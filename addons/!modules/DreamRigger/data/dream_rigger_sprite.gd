## A [Resource] that contains metadata for sprite-based character parts,
## managing texture, scaling, pivots, and joint positions.
@tool
class_name DreamRiggerSprite extends Resource

#region Properties

## Name of sprite.
var name: StringName:
    get:
        return resource_name
    
    set(value):
        resource_name = value
        emit_changed()

## The [Texture2D] asset used for rendering the sprite.
@export
var texture: Texture2D:
    get:
        return texture
    
    set(value):
        texture = value
        emit_changed()

## Float value determining how many pixels represent one world unit.[br]
## Must be greater than 0.
@export
var pixels_per_unit: float = 100.0:
    get:
        return pixels_per_unit
    
    set(value):
        pixels_per_unit = value
        pixels_to_units = _get_pixels_to_units()
        
        emit_changed()

## Read-only float value representing the conversion scale from pixels to world units.[br]
## Calculated as [code]1.0 / pixels_per_unit[/code] or [code]1.0[/code]
## if [member DreamRiggerSprite.pixels_per_unit] is [code]0[/code] or negative.
var pixels_to_units: float = _get_pixels_to_units()

## Representing the sprite's offset point (origin like pivot) in bottom-left coordinates.
@export
var offset: Vector3:
    get:
        return offset
    
    set(value):
        offset = value
        offset.z = 0
        emit_changed()

## An [Array] of [DreamRiggerJoint] resources defining connection points for the sprite. 
@export
var joints: Array[DreamRiggerJoint]:
    get:
        return joints
    
    set(value):
        joints = value
        _on_joints_changed()

## An displayable name for tool or debugging purposes.
var _display_name: String:
    get:
        if !name.is_empty():
            return name
        
        if is_instance_valid(texture) && !texture.resource_path.is_empty():
            return "res:" + texture.resource_path.get_basename().get_file()
        
        return "UNKNOWN"

func _get_property_list() -> Array[Dictionary]:
    
    var properties: Array[Dictionary] = []
    
    properties.append({
        "name": "name",
        "type": TYPE_STRING,
        "hint": PROPERTY_HINT_NONE,
        "usage": PROPERTY_USAGE_EDITOR
    })
    
    return properties

## Serialized version, incremental by default.
@export_storage
var version: int:
    get:
        return version
    
    set(value):
        version = value
        emit_changed()

#endregion

#region Signal methods

func _on_joints_changed() -> void:
    
    if !Engine.is_editor_hint():
        return
    
    var joint_created := false
    
    for index in joints.size():
        
        if is_instance_valid(joints[index]):
            continue 
        
        if index == 0:
            joints[index] = DreamRiggerJoint.new()
            joint_created = true
            continue
        
        var previous_joint := joints[index - 1]
        
        if !is_instance_valid(previous_joint):
            continue
        
        joints[index] = previous_joint.duplicate(true)
        joint_created = true
        pass
    
    if joint_created:
        notify_property_list_changed()
    
    _reassign_joints_event()
    emit_changed.call_deferred()
    pass

#endregion

#region Methods

func get_joint(name: StringName) -> DreamRiggerJoint:
    
    for joint: DreamRiggerJoint in joints:
        if joint.name == name:
            return joint
    
    return null

func _get_joint_index(name: StringName) -> int:
    
    for joint_index: int in joints.size():
        if joints[joint_index].name == name:
            return joint_index
    
    return -1

func _add_joint() -> DreamRiggerJoint:
    return _add_joint_at(joints.size())

func _create_new_joint_name() -> StringName:
    return "New Joint %s" % joints.size()

func _add_joint_at(index: int) -> DreamRiggerJoint:
    
    if index < 0 || index > joints.size():
        return null
    
    var new_joint := DreamRiggerJoint.new()
    new_joint.name = "New Joint %s" % joints.size()
    joints.insert(index, new_joint)
    
    notify_property_list_changed()
    _reassign_joints_event()
    emit_changed.call_deferred()
    
    return new_joint

func _add_joint_manually(joint: DreamRiggerJoint, index: int) -> void:
    
    if !is_instance_valid(joint):
        return
    
    if index < 0 || index > joints.size() + 1:
        return
    
    joints.insert(index, joint)
    
    notify_property_list_changed()
    _reassign_joints_event()
    emit_changed.call_deferred()
    
    pass

func _remove_joint_at(index: int) -> DreamRiggerJoint:
    
    if index < 0 || index >= joints.size():
        return null
    
    var removed_joint := joints[index]
    joints.remove_at(index)
    
    notify_property_list_changed()
    _reassign_joints_event()
    emit_changed.call_deferred()
    
    return removed_joint

func _remove_joint_by_name(name: StringName) -> DreamRiggerJoint:
    
    if joints.size() == 0:
        return null
    
    for joint_index: int in joints.size():
        
        var joint := joints[joint_index]
        
        if joint.name == name:
            
            joints.remove_at(joint_index)
    
            notify_property_list_changed()
            _reassign_joints_event()
            emit_changed.call_deferred()
            
            return joint
    
    return null

func _reassign_joints_event() -> void:
    
    if !Engine.is_editor_hint():
        return
    
    if joints.size() == 0:
        return
    
    for joint in joints:
        
        if !is_instance_valid(joint):
            continue
        
        if joint.changed.is_connected(emit_changed):
            joint.changed.disconnect(emit_changed)
        
        joint.changed.connect(emit_changed)
        
        pass
    
    pass

## Converts a position from world space to sprite space using [member DreamRiggerSprite.pixels_to_units].[br]
## Preserves Z-order by converting Z coordinate to small decimal offsets.
func to_sprite_space(value: Vector3) -> Vector3:
    
    var resolved_z: float = floor(value.z) * 0.0002
    
    value *= pixels_to_units
    value.z = resolved_z
    
    return value

func _get_pixels_to_units() -> float:
    return 1.0 / pixels_per_unit\
        if pixels_per_unit > 0\
        else 1.0

## Converts a position from sprite space to world space using [member DreamRiggerSprite.pixels_to_units].
func to_world_space(value: Vector3) -> Vector3:
    
    value /= pixels_to_units
    value.z = 0
    
    return value

## Creates a deep copy of the sprite resource and its joints.[br]
## [color=yellow]Note:[/color] Implemented as a workaround for array type casting limitations.[br]
## (issue [url=https://github.com/godotengine/godot/pull/71336]71336[/url]).
func _duplicate_manually() -> DreamRiggerSprite:
    
    if !Engine.is_editor_hint():
        return null
    
    var clone: DreamRiggerSprite = duplicate(true)
    
    var clone_joint := func(joint): return joint.duplicate(true)
    
    #https://github.com/godotengine/godot/pull/71336
    var cloned_joints: Array[DreamRiggerJoint]
    cloned_joints.assign(clone.joints.map(clone_joint))
    
    clone.joints = cloned_joints
    
    return clone

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

func _set(property: StringName, value: Variant) -> bool:
    
    if _migration_context != null:
        _migration_context.queue_property(property, value)
    
    return false

class MigrationContext extends RefCounted:
    
    var context: DreamRiggerSprite
    
    var queued_values:    Dictionary[StringName, Variant]
    var is_queue_started: bool
    
    var _finish_callback: Callable
    
    func _init(context: DreamRiggerSprite, finish_callback: Callable) -> void:
        
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
                
                move_property(&"pivot", &"offset")
                
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
