## A context class in DreamRigger's editor that contains the utilities necessary for
## controlling values or functions for items that users select or are editing,
## and for which sub-editor scripts require control over these items.
@tool
class_name DreamRiggerEditorContext extends RefCounted

## An enum to indicate which dimension the top-level [DreamRiggerPart2D]s or [DreamRiggerPart3D] in the context belongs to.
enum DimensionType {
    
    NONE,   ## Nothing
    TWO,    ## 2D
    THREE   ## 3D
}

#region Signals

## Emits when top-level part is changed after context of [DreamRiggerPart2D]s or [DreamRiggerPart3D]s changed.
signal root_part_changed(root_part: Node)

## Emits when context of [DreamRiggerPart2D]s or [DreamRiggerPart3D]s changed.
signal parts_changed(parts: Array[Node])

## Emits when context of [DreamRiggerPose]s changed.
signal poses_changed(poses: Array[DreamRiggerPose])

## Emits when context of [DreamRiggerSprite]s changed.
signal sprites_changed(sprites: Array[DreamRiggerSprite])

## Emits when context of [DreamRiggerJoint]s changed.
signal joints_changed(joints_with_sprite: Dictionary[DreamRiggerJoint, DreamRiggerSprite])

#endregion

#region Members

#region Context related members

## Current root part of [DreamRiggerPart2D]s or [DreamRiggerPart3D]s in context.
var root_part_node: Node

## Current context of [DreamRiggerPart2D]s or [DreamRiggerPart3D]s.
var part_nodes: Array[Node]

## Current context of [DreamRiggerPose]s.
var poses: Array[DreamRiggerPose]

## Current context of [DreamRiggerSprite]s.
var sprites: Array[DreamRiggerSprite]

## Lookup table for finding [DreamRiggerPose]'s owner([DreamRiggerPart2D] or [DreamRiggerPart3D]) in context.
var pose_owners: Dictionary[DreamRiggerPose, Node]

## Lookup table for finding [DreamRiggerSprite]'s owner([DreamRiggerPose]) in context.
var sprite_owners: Dictionary[DreamRiggerSprite, DreamRiggerPose]

## Lookup table for finding [DreamRiggerJoint]'s owner([DreamRiggerSprite]) in context.
var joint_owners: Dictionary[DreamRiggerJoint, DreamRiggerSprite]

#endregion

#region Animation related members

## Indicates currently recording to [AnimationPlayer] on editor.
var is_recording_animation: bool

## Current context of recording [AnimationPlayer] node.
var recording_animation_player: AnimationPlayer

## Current context of recording animation name of [member recording_animation_player].
var recording_animation_name: String

## Current context of recording [Animation] of [member recording_animation_name] from [member recording_animation_player].
var recording_animation: Animation

## Current context of recording [Animation]'s track path.
var recording_track_path: String

## Current context of recording [Animation]'s track type. ([enum Animation.TrackType])
var recording_track_type: int

#endregion

#region Operation related members

## Indicates dimension type of [member root_part_node] in context.
var current_dimension: DimensionType:
    get:
        match root_part_node:
            DreamRiggerPart2D: return DimensionType.TWO
            DreamRiggerPart3D: return DimensionType.THREE
        
        return DimensionType.NONE

## Indicates can insert animation key in context.
var can_insert_animation_key: bool:
    get:
        return is_recording_animation\
            && is_instance_valid(recording_animation_player)

var _undo_redo: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()

#endregion

#region Context APIs

## Reloads entire context, emits most of signals that related context change.
func refresh() -> void:
    
    set_part_context(part_nodes)
    set_pose_context(poses)
    set_sprite_context(sprites)
    
    pass

## Changes context of [DreamRiggerPart2D]s or [DreamRiggerPart3D]s.
func set_part_context(part_nodes: Array[Node], record_undo: bool = true) -> void:
    
    if record_undo:
        
        _undo_redo.create_action(
            "Change part context",
            UndoRedo.MERGE_DISABLE,
            EditorInterface.get_edited_scene_root()
        )
        
        var selection: EditorSelection = EditorInterface.get_selection()
        
        _undo_redo.add_do_method(self, &"set_part_context", part_nodes.duplicate(), false)
        _undo_redo.add_undo_method(self, &"set_part_context", self.part_nodes.duplicate(), false)
        
        _undo_redo.commit_action(false)
        pass
    
    self.part_nodes.assign(part_nodes.filter(DreamRiggerEditor.is_part_node_valid))
    
    var previous_root_part_node := self.root_part_node
    self.root_part_node = null
    
    for part_node in self.part_nodes:
        
        var root_part := DreamRiggerEditor.find_parent_part(part_node, true)
        
        if is_instance_valid(root_part):
            
            self.root_part_node = root_part
            break
        
        pass
    
    if previous_root_part_node != self.root_part_node:
        root_part_changed.emit.call_deferred(self.root_part_node)
    
    parts_changed.emit.call_deferred(self.part_nodes)
    
    var poses: Array[DreamRiggerPose]
    poses.append_array(self.part_nodes.map(func(node): return node.get(&"pose")))
    
    set_pose_context(poses, false)
    
    pass

## Update [member pose_owners] with given [DreamRiggerPart2D] or [DreamRiggerPart3D].
func update_pose_owner(sender: Node) -> void:
    
    if !DreamRiggerEditor.is_part_node_valid(sender):
        return
    
    var pose: DreamRiggerPose = sender.get_indexed(^"pose")
    
    if !is_instance_valid(pose):
        return
    
    if self.pose_owners.has(pose):
        return
    
    self.pose_owners[pose] = sender
    
    pass

## Changes context of [DreamRiggerPose]s.
func set_pose_context(poses: Array[DreamRiggerPose], record_undo: bool = true) -> void:
    
    if record_undo:
        
        _undo_redo.create_action(
            "Change pose context",
            UndoRedo.MERGE_DISABLE,
            EditorInterface.get_edited_scene_root()
        )
        
        _undo_redo.add_do_method(self, &"set_pose_context", poses.duplicate(), false)
        _undo_redo.add_undo_method(self, &"set_pose_context", self.poses.duplicate(), false)
        
        _undo_redo.commit_action(false)
        pass
    
    for pose in self.poses:
        
        if !is_instance_valid(pose):
            continue
        
        pose.changed_ext.disconnect(update_sprite_owner)
        
        pass
    
    self.poses.assign(poses.filter(is_instance_valid))
    poses_changed.emit.call_deferred(self.poses)
    
    for pose in self.poses:
        
        if !is_instance_valid(pose):
            continue
        
        pose.changed_ext.connect(update_sprite_owner)
        
        pass
    
    pass

## Update [member sprite_owners] with given [DreamRiggerPose].
func update_sprite_owner(sender: DreamRiggerPose) -> void:
    
    if !is_instance_valid(sender):
        return
    
    for sprite: DreamRiggerSprite in sender.sprites.values():
        
        if !is_instance_valid(sprite):
            continue
        
        #NOTE: Possible multiple assignment of same sprite resource into poses,
        #    : but I'll ignore it for now.
        if self.sprite_owners.has(sprite):
            continue
        
        self.sprite_owners[sprite] = sender
        
        pass
    
    pass

## Changes context of [DreamRiggerSprite]s.
func set_sprite_context(sprites: Array[DreamRiggerSprite], record_undo: bool = true) -> void:
    
    if record_undo:
        
        _undo_redo.create_action(
            "Change sprite context",
            UndoRedo.MERGE_DISABLE,
            EditorInterface.get_edited_scene_root()
        )
        
        _undo_redo.add_do_method(self, &"set_sprite_context", sprites.duplicate(), false)
        _undo_redo.add_undo_method(self, &"set_sprite_context", self.sprites.duplicate(), false)
        
        _undo_redo.commit_action(false)
        pass
    
    for sprite in self.sprites:
        
        if !is_instance_valid(sprite):
            continue
        
        sprite.changed_ext.disconnect(update_joint_owner)
        
        pass
    
    self.sprites.assign(sprites.filter(is_instance_valid))
    sprites_changed.emit.call_deferred(self.sprites)
    
    self.joint_owners.clear()
    
    for sprite in self.sprites:
        
        sprite.changed_ext.connect(update_joint_owner)
        update_joint_owner(sprite)
        
        pass
    
    joints_changed.emit.call_deferred(self.joint_owners)
    
    pass

## Update [member joint_owners] with given [DreamRiggerSprite].
func update_joint_owner(sender: DreamRiggerSprite) -> void:
    
    if !is_instance_valid(sender):
        return
    
    for joint in sender.joints:
        
        if !is_instance_valid(joint):
            continue
        
        #NOTE: Possible multiple assignment of same joint resource into sprites,
        #    : but I'll ignore it for now.
        if self.joint_owners.has(joint):
            continue
        
        self.joint_owners[joint] = sender
        
        pass
    
    pass

#endregion

#region Animation APIs

## Set [AnimationPlayer] that indicates recording target in context.
func set_recording_animation_player(target: AnimationPlayer) -> void:
    
    recording_animation_player = target
    
    pass

## Set [Animation] by name that indicates recording target in context.
## [br][br]
## This updates both [member recording_animation] and [member recording_animation_name].
func set_recording_animation(name: StringName) -> void:
    
    assert(is_instance_valid(recording_animation_player),  "AnimationPlayer not set in current context.")
    assert(recording_animation_player.has_animation(name), "Animation '%s' is not exist in current AnimationPlayer in context." % name)
    
    recording_animation_name = name
    recording_animation      = recording_animation_player.get_animation(name)
    
    pass

## Set animation track by given parameters.
func set_recording_animation_track(node: Node, property_name: StringName, type: Animation.TrackType) -> void:
    
    assert(is_instance_valid(node), "Given Node is not valid.")
    assert(node.is_inside_tree(),   "Given Node is not inside of tree.")
    
    var edited_scene_root := node.get_tree().edited_scene_root
    
    recording_track_path = "%s:%s" % [ edited_scene_root.get_path_to(node), property_name ]
    recording_track_type = type
    
    pass

## Clears context of recording [AnimationPlayer].
func clear_recording_animation_player() -> void:
    
    recording_animation_player = null
    
    pass

## Clears context of recording [Animation].
func clear_recording_animation_context() -> void:
    
    recording_animation_name = ""
    recording_animation      = null
    
    pass

## Clears context of recording [Animation]'s track.
func clear_recording_animation_track() -> void:
    
    recording_track_path = ""
    recording_track_type = 0
    
    pass

## Returns track index of [Animation] in [AnimationPlayer] that in context.
## [br][br]
## This method forwards result of [method Animation.find_track].
func get_current_recording_track_index() -> int:
    
    assert(is_instance_valid(recording_animation), "Animation context isn't exist.")
    
    return recording_animation.find_track(recording_track_path, recording_track_type)

## Creates [Animation]'s track in current context.
## [br][br]
## It requires setting context of animation with
## [method set_recording_animation_player],
## [method set_recording_animation],
## [method set_recording_animation_track].
func create_animation_track_with_current_context() -> void:
    
    assert(is_instance_valid(recording_animation), "Animation context isn't exist.")
    assert(!recording_track_path.is_empty(),       "Recording track context isn't set.")
    
    if get_current_recording_track_index() != -1:
        
        print_verbose("Ignoring create track with given contexts, track '%s' is already exist." % recording_track_path)
        return
    
    var track_index := recording_animation.add_track(recording_track_type)
    
    recording_animation.track_set_path(track_index, recording_track_path)
    recording_animation.track_set_interpolation_type(track_index, Animation.INTERPOLATION_NEAREST)
    recording_animation.value_track_set_update_mode(track_index, Animation.UPDATE_CAPTURE)
    
    pass

## Deletes [Animation]'s track in current context.
## [br][br]
## It requires setting context of animation with
## [method set_recording_animation_player],
## [method set_recording_animation],
## [method set_recording_animation_track].
func delete_animation_track_with_current_context() -> void:
    
    var track_index := get_current_recording_track_index()
    
    if track_index == -1:
        
        print_verbose("Ignoring delete track with given contexts, track '%s' is already not exist." % recording_track_path)
        clear_recording_animation_track()
        return
    
    recording_animation.remove_track(track_index)
    clear_recording_animation_track()
    
    pass

## Inserts [Animation] track key in current context.
## [br][br]
## This method forwards to [method Animation.track_insert_key].
func insert_animation_track_key_with_current_context(time: float, value: Variant) -> void:
    
    var track_index := get_current_recording_track_index()
    assert(track_index != -1, "Track is not found or not specified in context.")
    
    recording_animation.track_insert_key(track_index, time, value)
    
    pass

## Removes [Animation] track key in current context.
## [br][br]
## This method forwards to [method Animation.track_remove_key_at_time].
func remove_animation_track_key_with_current_context(time: float) -> void:
    
    var track_index := get_current_recording_track_index()
    assert(track_index != -1, "Track is not found or not specified in context.")
    
    recording_animation.track_remove_key_at_time(track_index, time)
    
    pass

## Records undo/redo actions that add animation keys to the [Animation] specified as the current context,
## using the given [EditorUndoRedoManager] and parameters.
## [br][br]
## It is recommended to check whether [member can_insert_animation_key] is [code]true[/code] when calling this method.
## [br][br]
## Most of logics are referenced from GodotEngine's source code. (
## [url=https://github.com/godotengine/godot/blob/a5a3f9ed2960529095ef59290ed7860a70157524/editor/animation/animation_track_editor.cpp#L4335]
## Link
## [/url]
## )
func record_undo_redo_insert_animation_key(
    undo_redo:      EditorUndoRedoManager,
    node:           Node,
    property_name:  StringName,
    value:          Variant,
    track_type:     int = Animation.TYPE_VALUE) -> void:
    
    set_recording_animation(DreamRiggerEditorInternalsHelper.get_editing_animation())
    set_recording_animation_track(node, property_name, track_type)
    
    undo_redo.add_do_method(self, &"set_recording_animation_player", recording_animation_player)
    undo_redo.add_undo_method(self, &"set_recording_animation_player", recording_animation_player)
    
    undo_redo.add_do_method(self, &"set_recording_animation", recording_animation_name)
    undo_redo.add_undo_method(self, &"set_recording_animation", recording_animation_name)
    
    undo_redo.add_do_method(self, &"set_recording_animation_track", node, property_name, track_type)
    undo_redo.add_undo_method(self, &"set_recording_animation_track", node, property_name, track_type)
    
    var exist_track_index := get_current_recording_track_index()
    
    if exist_track_index == -1:
        
        undo_redo.add_do_method(self, &"create_animation_track_with_current_context")
        undo_redo.add_undo_method(self, &"delete_animation_track_with_current_context")
        
        pass
    
    var time := DreamRiggerEditorInternalsHelper.get_current_time()
    
    undo_redo.add_do_method(self, &"insert_animation_track_key_with_current_context", time, value)
    
    if exist_track_index != -1:
        
        var existing_key_index: int = recording_animation.track_find_key(exist_track_index, time, Animation.FIND_MODE_APPROX)
        
        if existing_key_index != -1:
            
            var existing_key_value: Variant = recording_animation.track_get_key_value(exist_track_index, existing_key_index)
            undo_redo.add_undo_method(self, &"insert_animation_track_key_with_current_context", time, existing_key_value)
        
        else:
            undo_redo.add_undo_method(self, &"remove_animation_track_key_with_current_context", time)
        
        pass
    
    undo_redo.add_do_method(self, &"clear_recording_animation_track")
    undo_redo.add_undo_method(self, &"clear_recording_animation_track")
    
    pass

#endregion

#region API for mixed values

static func _get_property_or_default(targets: Array, property_path: NodePath, default: Variant) -> Variant:
    
    if targets.size() == 0:
        return default
    
    var first_element := targets.front()
    
    if !is_instance_valid(first_element):
        return default
    
    var first_value: Variant = first_element.get_indexed(property_path)
    
    for target in targets:
        
        if !is_instance_valid(target):
            return default
        
        if first_value != target.get_indexed(property_path):
            return default
        
        pass
    
    return first_value

## Returns property value from [DreamRiggerPart2D]s or [DreamRiggerParts3D]s in context.
func get_part_property_or_default(property_path: NodePath, default: Variant) -> Variant:
    
    return _get_property_or_default(part_nodes, property_path, default)

## Returns property value from [DreamRiggerPose]s in context.
func get_pose_property_or_default(property_path: NodePath, default: Variant) -> Variant:
    
    return _get_property_or_default(poses, property_path, default)

## Returns property value from [DreamRiggerSprite]s in context.
func get_sprite_property_or_default(property_path: NodePath, default: Variant) -> Variant:
    
    return _get_property_or_default(sprites, property_path, default)

## Returns property value from [DreamRiggerJoint]s in context.
func get_joint_property_or_default(property_path: NodePath, default: Variant) -> Variant:
    
    return _get_property_or_default(joint_owners.keys(), property_path, default)

#endregion

#region API for mixed state

static func _is_property_mixed(targets: Array, property_path: NodePath) -> bool:
    
    if targets.size() == 0:
        return false
    
    var first_element := targets.front()
    
    if !is_instance_valid(first_element):
        return false
    
    var first_value: Variant = first_element.get_indexed(property_path)
    
    return targets.any(
        func(target: Variant) -> bool:
            return (
                target.get_indexed(property_path) != first_value
                    if is_instance_valid(target)
                  else false
        )
    )

## Returns property values from [DreamRiggerPart2D]s or [DreamRiggerParts3D]s in context are mixed.
func is_part_property_mixed(property_path: NodePath) -> bool:
    
    return _is_property_mixed(part_nodes, property_path)

## Returns property values from [DreamRiggerPose]s in context are mixed.
func is_pose_property_mixed(property_path: NodePath) -> bool:
    
    return _is_property_mixed(poses, property_path)

## Returns property values from [DreamRiggerSprite]s in context are mixed.
func is_sprite_property_mixed(property_path: NodePath) -> bool:
    
    return _is_property_mixed(sprites, property_path)

## Returns property values from [DreamRiggerJoint]s in context are mixed.
func is_joint_property_mixed(property_path: NodePath) -> bool:
    
    return _is_property_mixed(joint_owners.keys(), property_path)

#endregion
