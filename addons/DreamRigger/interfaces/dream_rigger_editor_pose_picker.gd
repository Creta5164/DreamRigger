## An editor control class that wraps [EditorResourcePicker] for representing
## [DreamRiggerPart2D]'s or [DreamRiggerPart3D]'s [code]pose[/code]([DreamRiggerPose]) members in context.
@tool
class_name DreamRiggerEditorPosePicker extends Control

#region Members

## Indicates whether the user can perform actions on this control.
var enabled: bool:
    get:
        return enabled
    
    set(value):
        
        if is_instance_valid(_pose_picker):
            _pose_picker.visible = value
        
        _pose_picker_label.visible = !value
        enabled = value

@onready
var _pose_picker_label: Label = %"PosePickerLabel"
var _pose_picker: EditorResourcePicker

var _part_nodes: Array[Node]

#endregion

#region Signal methods

func _init() -> void:
    
    _pose_picker = EditorResourcePicker.new()
    _pose_picker.base_type = "DreamRiggerPose"
    
    add_child(_pose_picker)
    
    pass

func _ready() -> void:
    
    if is_part_of_edited_scene():
        return
    
    _pose_picker.resource_changed.connect(_on_pose_picker_resource_changed)
    
    var context := DreamRiggerEditor.get_context()
    context.parts_changed.connect(set_parts)
    
    pass

func _on_pose_picker_resource_changed(resource: Resource) -> void:
    
    if _part_nodes.size() == 0:
        return
    
    var undo_redo := EditorInterface.get_editor_undo_redo()
    
    undo_redo.create_action(
        "Pose picker : set pose",
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    var context := DreamRiggerEditor.get_context()
    
    var editor_inspector := EditorInterface.get_inspector()
    var previous_edited  := editor_inspector.get_edited_object()
    
    var new_pose: DreamRiggerPose = resource
    
    for part_node in _part_nodes:
        
        undo_redo.add_do_property(part_node, &"pose", new_pose)
        undo_redo.add_undo_property(part_node, &"pose", part_node.get_indexed(^"pose"))
        
        if context.can_insert_animation_key:
            
            context.record_undo_redo_insert_animation_key(
                undo_redo,
                part_node,
                &"pose",
                new_pose,
                Animation.TYPE_VALUE
            )
            
            pass
        
        pass
    
    var poses: Array[DreamRiggerPose]
    poses.append(new_pose)
    
    undo_redo.add_do_method(context, &"set_pose_context", poses, false)
    undo_redo.add_undo_method(context, &"set_pose_context", context.poses.duplicate(), false)
    
    undo_redo.commit_action()
    
    pass

func _on_part_pose_changed(pose: DreamRiggerPose) -> void:
    
    _update_pose_picker()
    pass

func _update_pose_picker() -> void:
    
    var context := DreamRiggerEditor.get_context()
    var parts   := context.part_nodes
    
    if parts.size() == 0:
        
        _set_edited_resource_without_signal(null)
        enabled = false
        
        return
    
    enabled = true
    
    var first_pose: DreamRiggerPose = parts.front().pose
    
    for part in parts:
        if first_pose != part.pose:
            #Mixed state
            _set_edited_resource_without_signal(null)
            
            return
    
    _set_edited_resource_without_signal(first_pose)
    
    pass

#endregion

#region API methods

## Set given parts into context.
func set_parts(parts: Array[Node]) -> void:
    
    for part_node in _part_nodes:
        
        if !DreamRiggerEditor.is_part_node_valid(part_node):
            continue
        
        part_node.disconnect(&"pose_changed", _on_part_pose_changed)
        
        pass
    
    _part_nodes.clear()
    _part_nodes.append_array(parts)
    
    for part_node in _part_nodes:
        
        part_node.connect(&"pose_changed", _on_part_pose_changed)
        
        pass
    
    _update_pose_picker()
    
    pass

func _set_edited_resource_without_signal(value: DreamRiggerPose) -> void:
    
    _pose_picker.set_block_signals(true)
    _pose_picker.edited_resource = value
    _pose_picker.set_block_signals(false)
    
    pass

#endregion
