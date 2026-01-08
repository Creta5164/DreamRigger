@tool
class_name DreamRiggerEditorJointInspector extends Control

#region Members

## Indicates whether the user can perform actions on this control.
@export
var enabled: bool = true:
    get:
        return enabled
    
    set(value):
        
        if !is_node_ready():
            
            ready.connect(set.bind(&"enabled", value), ConnectFlags.CONNECT_ONE_SHOT)
            return
        
        _joint_list.enabled = value
        _position_editor_property.read_only = !value
        
        enabled = value
        
        pass

var _undo_redo := EditorInterface.get_editor_undo_redo()

@onready var _joint_list:         DreamRiggerEditorJointItemList = %JointList
@onready var _position_container: HFlowContainer                 = %PositionContainer

var _joints: Array[DreamRiggerJoint]

var _position_editor_property: EditorProperty

var _joint_position: Vector2:
    get:
        var result: Vector2
        
        result.x = DreamRiggerEditorContext._get_property_or_default(_joints, ^"position:x", 0)
        result.y = DreamRiggerEditorContext._get_property_or_default(_joints, ^"position:y", 0)
        
        return result

#endregion

#region Signal methods

func _ready() -> void:
    
    if is_part_of_edited_scene():
        return
    
    var context := DreamRiggerEditor.get_context()
    context.sprites_changed.connect(set_sprites)
    
    _joint_list.joint_selected.connect(_on_joint_list_selection_changed)
    
    _position_editor_property = EditorInspector.instantiate_property_editor(
        self,
        TYPE_VECTOR2,
        &"_joint_position",
        PROPERTY_HINT_NONE,
        "",
        PROPERTY_USAGE_EDITOR,
        true
    )
    _position_editor_property.draw_label = false
    _position_editor_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    _position_container.add_child(_position_editor_property)
    
    _position_editor_property.set_object_and_property(self, &"_joint_position")
    
    _position_editor_property.property_changed.connect(_on_position_property_changed)
    
    visibility_changed.connect(_update_content)
    
    pass

func _on_joint_list_selection_changed(joints: Array[DreamRiggerJoint]) -> void:
    
    for joint in _joints:
        
        if !is_instance_valid(joint):
            continue
        
        joint.changed_ext.disconnect(_on_joint_changed)
        
        pass
    
    _joints.clear()
    _joints.append_array(joints)
    
    for joint in _joints:
        
        if !is_instance_valid(joint):
            continue
        
        joint.changed_ext.connect(_on_joint_changed)
        
        pass
    
    _update_content()
    
    pass

func _on_joint_changed(sender: DreamRiggerJoint) -> void:
    
    _update_content()
    
    pass


func _on_position_property_changed(
    property: StringName,
    value:    Variant,
    field:    StringName,
    changing: bool) -> void:
    
    if _joints.size() == 0:
        return
    
    _undo_redo.create_action(
        "Set position %s of joint(s)" % field,
        UndoRedo.MERGE_ENDS,
        EditorInterface.get_edited_scene_root()
    )
    
    for joint in _joints:
        
        var old_value: Vector3 = joint.get_indexed(^"position")
        var new_value: Vector3 = old_value
        
        match field:
            "x": new_value.x = value.x
            "y": new_value.y = value.y
        
        _undo_redo.add_do_property(joint, &"position", new_value)
        _undo_redo.add_undo_property(joint, &"position", old_value)
        
        pass
    
    _undo_redo.commit_action()
    
    pass

#endregion

#region API methods

## Set context of [DreamRiggerSprite]s for handling [DreamRiggerJoint]s.
func set_sprites(sprites: Array[DreamRiggerSprite]) -> void:
    
    enabled = sprites.size() == 0
    
    _joint_list.set_sprites(sprites)
    
    pass

#endregion

#region Operation methods

func _update_content() -> void:
    
    if !is_visible_in_tree():
        return
    
    _position_editor_property.update_property()
    
    pass

#endregion
