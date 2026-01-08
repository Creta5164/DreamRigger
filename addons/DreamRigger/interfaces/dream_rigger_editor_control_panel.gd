## A editor control panel for DreamRigger.
## 
## Users can setup and compose sprites with [DreamRiggerPart2D] or [DreamRiggerPart3D]
## and [DreamRiggerPose], [DreamRiggerSprite], [DreamRiggerJoint].
## [br][br]
## This class is typically used to integrates between the [DreamRiggerEditorPosePreviewer], [DreamRiggerEditorPartTree],
## [DreamRiggerEditorPoseSpritesList] and Inspectors provided in the control panel.
@tool
class_name DreamRiggerEditorControlPanel extends Control

#region Members

@onready var _record_to_track_button: CheckButton = %RecordToTrackButton

@onready var _pose_previewer:   DreamRiggerEditorPosePreviewer   = %PosePreviewContainer
@onready var _part_hierarchy:   DreamRiggerEditorPartTree        = %PartHierarchy

@onready var _pose_sprite_list: DreamRiggerEditorPoseSpritesList = %PoseSpriteList

@onready var _part_inspector:   DreamRiggerEditorPartInspector   = %Parts
@onready var _sprite_inspector: DreamRiggerEditorSpriteInspector = %Sprites
@onready var _joint_inspector:  DreamRiggerEditorJointInspector  = %Joints

#endregion

#region Signal methods

func _ready() -> void:
    
    if is_part_of_edited_scene():
        return
    
    var context := DreamRiggerEditor.get_context()
    
    _record_to_track_button.toggled.connect(_on_record_to_track_button_toggled)
    _record_to_track_button.set_pressed_no_signal(context.is_recording_animation)
    
    _part_hierarchy.hovering_item_changed.connect(_on_part_hierarchy_hovering_item_changed)
    
    _pose_sprite_list.hovering_item_changed.connect(_on_pose_sprite_list_hovering_item_changed)
    _pose_sprite_list.recording_undo_redo.connect(_on_pose_sprite_list_recording_undo_redo)
    _pose_sprite_list.selection_changed.connect(_on_pose_sprite_list_selection_changed)
    
    var selection := EditorInterface.get_selection()
    
    context.set_part_context(selection.get_selected_nodes())
    
    pass

func _on_record_to_track_button_toggled(toggled_on: bool) -> void:
    
    var context := DreamRiggerEditor.get_context()
    context.is_recording_animation = toggled_on
    
    pass

func _on_part_hierarchy_hovering_item_changed(part_node: Node) -> void:
    
    var is_hovering: bool = is_instance_valid(part_node)
    
    var context := DreamRiggerEditor.get_context()
    
    var inspecting_part_nodes: Array[Node]
    
    if is_hovering:
        inspecting_part_nodes.append(part_node)
    
    elif context.part_nodes.size() > 0:
        inspecting_part_nodes.assign(context.part_nodes)
        part_node = context.part_nodes.front()
    
    _part_inspector.set_part_nodes(inspecting_part_nodes)
    _part_inspector.enabled = !is_hovering
    
    pass

func _on_pose_sprite_list_hovering_item_changed(sprite: DreamRiggerSprite) -> void:
    
    var is_hovering: bool = is_instance_valid(sprite)
    
    var context := DreamRiggerEditor.get_context()
    
    var inspecting_sprites: Array[DreamRiggerSprite]
    
    if is_hovering:
        inspecting_sprites.append(sprite)
    
    elif context.sprites.size() > 0:
        inspecting_sprites.assign(context.sprites)
        sprite = context.sprites.front()
    
    _pose_previewer.set_sprite_preview(sprite)
    _sprite_inspector.set_sprites(inspecting_sprites)
    _joint_inspector.set_sprites(inspecting_sprites)
    
    _sprite_inspector.enabled = !is_hovering
    _joint_inspector.enabled = !is_hovering
    
    pass

func _on_pose_sprite_list_recording_undo_redo(
    undo_redo:        EditorUndoRedoManager,
    first_selected:   int,
    selected_indexes: Array[int]) -> void:
    
    if first_selected == -1:
        return
    
    var pose := _pose_sprite_list._binding_pose
    
    if !is_instance_valid(pose):
        return
    
    var selected_pose_uid := pose.index_to_uid(first_selected)
    
    var context := DreamRiggerEditor.get_context()
    
    for part_node in context.part_nodes:
        
        if part_node.get(&"pose") != pose:
            continue
        
        undo_redo.add_do_property(part_node, &"pose_uid", selected_pose_uid)
        undo_redo.add_undo_property(part_node, &"pose_uid", part_node.get_indexed(^"pose_uid"))
        
        if context.can_insert_animation_key:
            
            context.record_undo_redo_insert_animation_key(
                undo_redo,
                part_node,
                &"pose_uid",
                selected_pose_uid,
                Animation.TYPE_VALUE
            )
            
            pass
        
        pass
    
    pass

func _on_pose_sprite_list_selection_changed(
    first_selected:   int,
    selected_indexes: Array[int]) -> void:
    
    var context := DreamRiggerEditor.get_context()
    
    var sprites: Array[DreamRiggerSprite] = _pose_sprite_list.get_selected_sprites()
    
    #If there's nothing selected then show contexted part's sprite instead.
    if sprites.size() == 0:
        
        var displaying_sprite: DreamRiggerSprite = context.get_part_property_or_default(^"sprite", null)
        
        if is_instance_valid(displaying_sprite):
            sprites.append(displaying_sprite)
        
        pass
    
    context.set_sprite_context(sprites, false)
    
    pass

#endregion
