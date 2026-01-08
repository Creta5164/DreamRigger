## A [Node2D]-based rigging component that manages character parts through pose and sprite manipulation.
## 
## Handles hierarchical positioning, joint management, and sprite rendering for modular character animation systems.
@tool
class_name DreamRiggerPart2D extends Sprite2D

#region Signals

## Emitted when position recalculation is needed for this part or its children.
signal request_resolve_position(sender: Node)

## Emitted when the [member pose] property is modified.
signal pose_changed(pose: DreamRiggerPose)

## Emitted when the assigned [member pose] resource is modified.
signal pose_modified(pose: DreamRiggerPose)

## Emitted when the [member sprite] property is modified.
signal sprite_changed(sprite: DreamRiggerSprite)

## Emitted when the [member Sprite2D.flip_h] or [member Sprite2D.flip_v] property is modified.
signal flip_state_changed(h: bool, v: bool)

## Emitted when [member position_offset] value changed.
signal position_offset_changed(offset: Vector3)

## Emitted when [member rotation] value changed.
signal rotation_z_changed(degree: float)

## Emitted after part position is resolved by nearby part and child parts.
signal position_resolved()

#endregion

#region Members

## Opens control panel in editor.
@export_tool_button("Open control panel", "Edit")
var _editor_open_control_panel: Callable:
    get:
        return func() -> void:
            
            if !Engine.is_editor_hint():
                return
            
            DreamRiggerEditor.open_control_panel()
            
            pass

## Boolean flag that determines if this part is the root node in the rig hierarchy.
@export
var is_root_part: bool:
    get:
        return is_root_part
    
    set(value):
        is_root_part = value
        request_resolve_position.emit(self)

## Reference to a [DreamRiggerPose] resource defining available poses for this part.
@export
var pose: DreamRiggerPose:
    get:
        return pose
        
    set(value):
        if pose == value:
            return
        
        _reassign_pose(pose, value)
        pose = value
        
        _on_pose_changed()

## Integer uid for selecting the current pose from the [member pose] resource.
@export
var pose_uid: int:
    get:
        
        return pose_uid
    
    set(value):
        if pose_uid == value:
            return
        
        pose_uid = value
        
        _on_pose_id_changed()

## Reference to a [DreamRiggerSprite] resource containing visual data.
@export
var sprite: DreamRiggerSprite:
    get:
        return sprite
        
    set(value):
        if sprite == value:
            return
        
        sprite = value
        _on_sprite_changed()

## [Vector3] positional offset from parent node position.
@export
var position_offset: Vector3:
    get:
        return position_offset
    
    set(value):
        if position_offset == value:
            return
        
        position_offset = value
        position_offset.z = floor(position_offset.z)
        
        if is_root_part:
            resolve_positions()
        
        else:
            request_resolve_position.emit(self)
        
        position_offset_changed.emit(position_offset)

## [float] Z axis rotation.[br]
## It's not bound with [member Node2D.transform], it'll be set to this z value when position resolved.
@export
var rotation_z: float:
    get:
        return rotation_z
    
    set(value):
        if rotation_z == value:
            return
        
        rotation_z = value
        
        if is_root_part:
            resolve_positions()
        
        else:
            request_resolve_position.emit(self)
        
        rotation_z_changed.emit(rotation_z)

## Serialized version, incremental by default. (See [constant DreamRiggerMetadata.VERSION])
@export_storage
var version: int:
    get:
        return version
    
    set(value):
        version = value

## Dictionary caching [DreamRiggerJoint] data for efficient position calculations from
## current [member sprite].
var joints_lookup: Dictionary[StringName, DreamRiggerJoint]

## Dictionary caching [DreamRiggerJoint] position for efficient position calculations from
## current [member sprite].
var resolved_joint_positions: Dictionary[StringName, Vector3]

var _flip_h: bool
var _flip_v: bool
var _is_position_resolving: bool

var _relative_z: float:
    get:
        if is_root_part:
            return 0
        
        return _relative_z
    
    set(value):
        _relative_z = value
        resolve_positions()

## Resolved [member Sprite2D.flip_h] in part hierarchy.
var resolved_flip_h: bool:
    get:
        if is_root_part:
            return _flip_h
        
        return _parent_flip_h != _flip_h

## Resolved [member Sprite2D.flip_v] in part hierarchy.
var resolved_flip_v: bool:
    get:
        if is_root_part:
            return _flip_v
        
        return _parent_flip_v != _flip_v

var _parent_flip_h := false:
    get:
        return _parent_flip_h
    
    set(value):
        _parent_flip_h = value
        resolve_positions()

var _parent_flip_v := false:
    get:
        return _parent_flip_v
    
    set(value):
        _parent_flip_v = value
        resolve_positions()

func _get(property: StringName) -> Variant:
    
    match property:
        
        "flip_h":
            return _flip_h
        
        "flip_v":
            return _flip_v
        
        "joints":
            
            if is_instance_valid(sprite):
                return sprite.joints
            
            else:
                return []
            
            pass
    
    return null

func _set(property: StringName, value: Variant) -> bool:
    
    if _migration_context != null:
        _migration_context.queue_property(property, value)
    
    match property:
        
        "flip_h":
            
            if _is_position_resolving:
                flip_h = value
                return true
            
            _flip_h = value
            
            if is_root_part:
                resolve_positions()
            
            else:
                request_resolve_position.emit(self)
            
            flip_state_changed.emit(_flip_h, _flip_v)
            
            return true
            
        "flip_v":
            
            if _is_position_resolving:
                flip_v = value
                return true
            
            _flip_v = value
            
            if is_root_part:
                resolve_positions()
            
            else:
                request_resolve_position.emit(self)
            
            flip_state_changed.emit(_flip_h, _flip_v)
            
            return true
        
        "joints":
            
            if !is_instance_valid(sprite):
                return true
            
            var joints: Array[DreamRiggerJoint]
            joints.assign(value)
            
            sprite.joints = joints
            sprite._on_joints_changed()
            
            return true
    
    return false

func _get_property_list() -> Array[Dictionary]:
    
    var properties: Array[Dictionary] = []
    
    properties.append({
        "name":        "joints",
        "type":        TYPE_ARRAY,
        "hint":        PROPERTY_HINT_RESOURCE_TYPE,
        "hint_string": "24/17:DreamRiggerJoint",
        "usage":       PROPERTY_USAGE_DEFAULT
    })
    
    return properties

#endregion

#region Signal methods

func _init() -> void:
    
    self.centered = true
    pass

func _enter_tree() -> void:
    
    self.child_entered_tree.connect(_on_child_entered_tree)
    self.child_exiting_tree.connect(_on_child_exiting_tree)
    self.editor_state_changed.connect(resolve_positions)
    
    pass

func _exit_tree() -> void:
    
    self.child_entered_tree.disconnect(_on_child_entered_tree)
    self.child_exiting_tree.disconnect(_on_child_exiting_tree)
    self.editor_state_changed.disconnect(resolve_positions)
    
    pass

func _on_child_entered_tree(node: Node) -> void:
    
    if node is DreamRiggerPart2D:
        node.request_resolve_position.connect(resolve_child_position)
    
    #리페런팅 시 위치를 재지정하는 것으로 보임, 1프레임 대기
    await get_tree().process_frame
    
    resolve_child_position(node)
    pass

func _on_child_exiting_tree(node: Node) -> void:
    
    if node is DreamRiggerPart2D:
        
        node.request_resolve_position.disconnect(resolve_child_position)
        node._relative_z = 0
        
        pass
    
    pass

func _ready() -> void:
    
    _reassign_pose(null, pose)
    pass

func _on_pose_changed() -> void:
    
    pose_changed.emit(pose)
    _on_pose_id_changed()
    
    pass

func _on_pose_modified() -> void:
    
    pose_modified.emit(pose)
    _on_pose_id_changed()
    _on_sprite_changed()
    
    pass

func _on_pose_id_changed() -> void:
    
    if !is_instance_valid(pose):
        
        sprite = null
        return
    
    sprite = pose.get_sprite(pose_uid)
    
    pass

func _on_sprite_changed() -> void:
    
    joints_lookup.clear()
    resolved_joint_positions.clear()
    
    if !is_instance_valid(sprite):
        
        texture = null
        resolve_positions()
        sprite_changed.emit(sprite)
        return
    
    texture = sprite.texture
    self.scale = Vector2.ONE * sprite.pixels_to_units
    
    for joint in sprite.joints:
        joints_lookup[joint.name] = joint
    
    resolve_positions()
    sprite_changed.emit(sprite)
    pass

#endregion

#region Methods

## Finds parent or root part.
static func find_parent_part(node: Node, find_root: bool = false, topmost_node: Node = null) -> DreamRiggerPart2D:
    
    if !is_instance_valid(topmost_node):
        topmost_node = node.get_tree().root
    
    if !is_instance_valid(node) || node == topmost_node:
        return null
    
    if node is DreamRiggerPart2D:
        
        if !find_root || (find_root && node.is_root_part):
            return node
    
    var parent: Node = node.get_parent()
    
    return find_parent_part(parent, find_root, topmost_node)

## Finds all of family part in hierarchy of given part.
static func find_all_family_parts(part: DreamRiggerPart2D) -> Array[DreamRiggerPart2D]:
    
    if !is_instance_valid(part):
        return []
    
    var family_parts: Array[DreamRiggerPart2D]
    
    var root_part := find_parent_part(part, true)
    
    if !is_instance_valid(root_part):
        return [ part ]
    
    _iterate_get_child_parts(part, family_parts)
    
    return family_parts

static func _iterate_get_child_parts(part: DreamRiggerPart2D, parts: Array[DreamRiggerPart2D]) -> void:
    
    if !is_instance_valid(part):
        return
    
    parts.append(part)
    
    for child in part.get_children():
        if child is DreamRiggerPart2D:
            _iterate_get_child_parts(child, parts)
    
    pass

## Updates the position based on current sprite data and initiates joint position updates.
func resolve_positions() -> void:
    
    _is_position_resolving = true
    
    var resolved_rotation_z := rotation_z
    
    if _parent_flip_h != _parent_flip_v:
        
        resolved_rotation_z = deg_to_rad(resolved_rotation_z)
        
        var radian_y := -sin(resolved_rotation_z)   #Inverted
        var radian_x :=  cos(resolved_rotation_z)
        
        resolved_rotation_z = rad_to_deg(atan2(radian_y, radian_x))
        
        pass
    
    self.rotation_degrees = -resolved_rotation_z
    self.z_index = position_offset.z
    
    if is_instance_valid(sprite):
        
        var offset := sprite.offset
        
        if resolved_flip_h: offset.x *= -1
        if resolved_flip_v: offset.y *= -1
        
        self.offset = -Vector2(offset.x, offset.y)
        self.flip_h = resolved_flip_h
        self.flip_v = resolved_flip_v
        
        pass
    
    resolve_joints()
    position_resolved.emit()
    
    _is_position_resolving = false
    pass

## Updates joint positions for all child nodes in the rig hierarchy based on current [member sprite] data.
func resolve_joints() -> void:
    
    if !is_instance_valid(sprite):
        return
    
    for child_node in get_children():
        resolve_child_position(child_node)
    
    pass

## Calculates and applies position updates for a specified child node using joint data and position_offset information.
func resolve_child_position(child_node: Node = null) -> void:
    
    if !is_instance_valid(sprite) || child_node.get_parent() != self || child_node is not Node2D:
        return
    
    var resolved_position := Vector3.ZERO
    var is_part           := false
    
    var joint_position := Vector3.ZERO
    var child_offset   := Vector3.ZERO
    
    var has_joint := joints_lookup.has(child_node.name)
    
    if child_node is DreamRiggerPart2D:
        
        if child_node.is_root_part:
            return
        
        child_offset = child_node.position_offset
        
        child_offset.z = child_offset.z - _relative_z
        
        child_node._relative_z = child_offset.z
        
        child_node._parent_flip_h = resolved_flip_h
        child_node._parent_flip_v = resolved_flip_v
        
    #If there are no joints and the node is not a DreamRiggerPart2D, it is not controlled.
    elif !has_joint:
        return
    
    if has_joint:
        
        var joint: DreamRiggerJoint = joints_lookup[child_node.name]
        
        if is_instance_valid(joint):
            joint_position = joint.position
    
    #Joint is absolute.
    resolved_position = joint_position + child_offset
    resolved_position.z = child_offset.z
    
    resolved_position = (sprite.to_sprite_space(resolved_position) * Vector3(scale.x, scale.y, 1))
    
    if resolved_flip_h: resolved_position.x *= -1
    if resolved_flip_v: resolved_position.y *= -1
    
    resolved_joint_positions[child_node.name] = resolved_position
    child_node.position = Vector2(resolved_position.x, resolved_position.y)
    
    pass

func _reassign_pose(old_pose: DreamRiggerPose, new_pose: DreamRiggerPose) -> void:
    
    if is_instance_valid(old_pose):
        
        if old_pose.changed.is_connected(_on_pose_modified):
            old_pose.changed.disconnect(_on_pose_modified)
        
        pass
    
    if is_instance_valid(new_pose):
        
        if !new_pose.changed.is_connected(_on_pose_modified):
            new_pose.changed.connect(_on_pose_modified)
        
        pass
    
    pass

#endregion

#region Migration

## Handles version control that makes old version up to date.
var _migration_context := MigrationContext.new(
        self,
        _on_migration_finished
    )

func _on_migration_finished() -> void:
    
    #TODO: Write finalization logic here for after migration if necessary.
    
    _migration_context = null
    
    pass

class MigrationContext extends RefCounted:
    
    var context: DreamRiggerPart2D
    
    var queued_values:    Dictionary[StringName, Variant]
    var is_queue_started: bool
    
    var _finish_callback: Callable
    
    func _init(context: DreamRiggerPart2D, finish_callback: Callable) -> void:
        
        self.context     = context
        _finish_callback = _finish_callback
        
        pass
    
    func queue_property(property_name: StringName, value: Variant) -> void:
        
        set_property(property_name, value)
        
        if !is_queue_started:
            
            is_queue_started = true
            _process.call_deferred()
        
        pass
    
    func _process() -> void:
        
        if !is_instance_valid(context):
            return
        
        if context.version >= DreamRiggerMetadata.VERSION:
            
            context._migration_context = null
            return
        
        while context.version < DreamRiggerMetadata.VERSION:
            
            _migrate(context.version)
            context.version += 1
            
            pass
        
        for property_name: StringName in queued_values:
            
            if property_name == &"version":
                continue
            
            context.set(property_name, queued_values[property_name])
            
            pass
        
        if is_instance_valid(_finish_callback):
            _finish_callback.call()
        
        context._migration_context = null
        
        pass
    
    func _migrate(current_version: int) -> void:
        
        match DreamRiggerMetadata.to_semantic_version(current_version):
            
            #TODO: Write migration logic here if necessary.
            &"alpha-1.0.0":
                
                move_property(&"offset", &"position_offset")
                delete_property(&"sprite_node")
                
                pass
            
            pass
        
        pass
    
    func get_property(name: StringName) -> Variant:
        
        return queued_values[name]\
            if queued_values.has(name)\
          else null
    
    func set_property(name: StringName, value: Variant) -> void:
        
        queued_values[name] = value
        
        pass
    
    func move_property(from: StringName, to: StringName) -> void:
        
        set_property(to, delete_property(from))
        
        pass
    
    func delete_property(name: StringName) -> Variant:
        
        var value := get_property(name)
        queued_values.erase(name)
        
        return value
    
    pass

#endregion
