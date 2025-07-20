@tool
class_name DreamRiggerControlPanel extends Control

const EMPTY_SPRITE: Texture2D = preload("res://addons/!modules/DreamRigger/resources/empty_sprite.png")

const INSPECTOR_COLLAPSE_WIDTH: float = 350

var _editor_selection := EditorInterface.get_selection()
var _undo_redo        := EditorInterface.get_editor_undo_redo()

var _edit_part_root: Node

var _left_panel_container: VSplitContainer
var _pose_previewer:       DreamRiggerPosePreviewer
var _hierarchy_tree:       DreamRiggerPartTree

var _right_panel_container: VSplitContainer

var _record_to_track_button: CheckButton

var _pose_browser:          DreamRiggerPoseBrowser

var _part_inspector:        DreamRiggerPartInspector
var _sprite_inspector:      DreamRiggerSpriteInspector
var _scratch_pad_inspector: DreamRiggerScratchPadInspector

var _panel_minimum_size: float

var _is_editor_selection_changing: bool

var _is_recording: bool

var _pose_list_context_popup: PopupMenu

func _enter_tree() -> void:
    
    _left_panel_container  = %"LeftPanelContainer"
    _pose_previewer        = %"PosePreviewContainer"
    _hierarchy_tree        = %"HierarchyTree"
    
    _right_panel_container  = %"RightPanelContainer"
    
    _record_to_track_button = %"RecordToTrackButton"
    _pose_browser           = %"PoseBrowserContainer"
    _part_inspector         = %"Part"
    _sprite_inspector       = %"Sprite"
    _scratch_pad_inspector  = %"Scratch pad"
    
    if !_hierarchy_tree.part_selected.is_connected(_on_hierarchy_tree_part_selected):
        _hierarchy_tree.part_selected.connect(_on_hierarchy_tree_part_selected)
    
    if !_record_to_track_button.toggled.is_connected(_on_record_to_track_button_toggled):
        _record_to_track_button.toggled.connect(_on_record_to_track_button_toggled)
    
    if !_pose_browser.recordable_property_changed.is_connected(_on_recordable_property_changed):
        _pose_browser.recordable_property_changed.connect(_on_recordable_property_changed)
    
    if !_pose_browser.pose_resource_changed.is_connected(_on_pose_browser_pose_resource_changed):
        _pose_browser.pose_resource_changed.connect(_on_pose_browser_pose_resource_changed)
    
    if !_pose_browser.sprite_selection_changed.is_connected(_on_pose_browser_selection_changed):
        _pose_browser.sprite_selection_changed.connect(_on_pose_browser_selection_changed)
    
    if !_pose_browser.hovering_item_changed.is_connected(_pose_previewer.update_preview):
        _pose_browser.hovering_item_changed.connect(_pose_previewer.update_preview)
    
    if is_instance_valid(_editor_selection):
        
        if !_editor_selection.selection_changed.is_connected(_on_editor_selection_changed):
            _editor_selection.selection_changed.connect(_on_editor_selection_changed)
        
        _on_editor_selection_changed.call_deferred()
    
    if !_part_inspector.recordable_property_changed.is_connected(_on_recordable_property_changed):
        _part_inspector.recordable_property_changed.connect(_on_recordable_property_changed)
    
    if !_scratch_pad_inspector.recordable_property_changed.is_connected(_on_recordable_property_changed):
        _scratch_pad_inspector.recordable_property_changed.connect(_on_recordable_property_changed)
    
    pass

func _exit_tree() -> void:
    
    _unbind_root_part()
    
    if _hierarchy_tree.part_selected.is_connected(_on_hierarchy_tree_part_selected):
        _hierarchy_tree.part_selected.disconnect(_on_hierarchy_tree_part_selected)
    
    if _record_to_track_button.toggled.is_connected(_on_record_to_track_button_toggled):
        _record_to_track_button.toggled.disconnect(_on_record_to_track_button_toggled)
    
    if _pose_browser.recordable_property_changed.is_connected(_on_recordable_property_changed):
        _pose_browser.recordable_property_changed.disconnect(_on_recordable_property_changed)
    
    if _pose_browser.pose_resource_changed.is_connected(_on_pose_browser_pose_resource_changed):
        _pose_browser.pose_resource_changed.disconnect(_on_pose_browser_pose_resource_changed)
    
    if _pose_browser.sprite_selection_changed.is_connected(_on_pose_browser_selection_changed):
        _pose_browser.sprite_selection_changed.disconnect(_on_pose_browser_selection_changed)
    
    if _pose_browser.hovering_item_changed.is_connected(_pose_previewer.update_preview):
        _pose_browser.hovering_item_changed.disconnect(_pose_previewer.update_preview)
    
    if is_instance_valid(_editor_selection):
        
        if _editor_selection.selection_changed.is_connected(_on_editor_selection_changed):
            _editor_selection.selection_changed.disconnect(_on_editor_selection_changed)
    
    if _part_inspector.recordable_property_changed.is_connected(_on_recordable_property_changed):
        _part_inspector.recordable_property_changed.disconnect(_on_recordable_property_changed)
    
    if _scratch_pad_inspector.recordable_property_changed.is_connected(_on_recordable_property_changed):
        _scratch_pad_inspector.recordable_property_changed.disconnect(_on_recordable_property_changed)
    
    pass

func _on_hierarchy_tree_part_selected(part: Node) -> void:
    
    if !_is_editor_selection_changing:
        
        _editor_selection.clear()
        _editor_selection.add_node(part)
        
        pass
    
    _pose_previewer.bind_part(part)
    _pose_browser.bind_part(part)
    
    _part_inspector.bind_part(part)
    _scratch_pad_inspector.bind_part(part)
    
    _pose_previewer.refresh()
    _pose_browser.refresh()
    
    pass

func _on_pose_browser_pose_resource_changed(part: Node, pose: DreamRiggerPose) -> void:
    
    _undo_redo.create_action(
        "Change pose asset of '%s'" % [ part.name ],
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    var pose_list := _pose_browser._pose_list
    
    var empty_array: Array[int]
    
    _undo_redo.add_do_property(part, &"pose", pose)
    _undo_redo.add_do_method(_pose_browser, &"set_selection", -1, empty_array)
    _undo_redo.add_undo_property(part, &"pose", part.pose)
    _undo_redo.add_undo_method(_pose_browser, &"set_selection", pose_list._first_selected_index, pose_list._selected_indexes.duplicate())
    _undo_redo.commit_action()
    
    pass

func _on_pose_browser_selection_changed(
    part:         Node,
    first_sprite: DreamRiggerSprite,
    sprites:      Array[DreamRiggerSprite]) -> void:
    
    _sprite_inspector.set_part_context(part)
    _sprite_inspector.bind_sprites(sprites)
    
    pass

func _on_pose_browser_pose_selected(part: Node, selected_uid: int) -> void:
    
    var pose: DreamRiggerPose
    
    if part is DreamRiggerPart2D || part is DreamRiggerPart3D:
        pose = part.pose
    
    if !is_instance_valid(pose):
        return
    
    var first_selection_sprite := pose.get_sprite(selected_uid)
    
    _undo_redo.create_action(
        "Change pose uid (%s) of '%s'" % [ first_selection_sprite._display_name, part.name ],
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    _undo_redo.add_do_property(part, &"pose_uid", selected_uid)
    _undo_redo.add_undo_property(part, &"pose_uid", part.pose_uid)
    
    _on_recordable_property_changed(part, &"pose_uid", selected_uid)
    
    _undo_redo.commit_action()
    
    pass

func _on_editor_selection_changed() -> void:
    
    var targets: Array[Node] = _editor_selection\
        .get_selected_nodes()
    
    #NOTE: Same as the Animation Player window, the last selected target is always visible.
    if targets.size() == 0:
        return
    
    _is_editor_selection_changing = true
    
    var scene_root_node := EditorInterface.get_edited_scene_root()
    
    for target: Node in targets:
        
        var root_part := (
            DreamRiggerPart2D.find_parent_part(target, true, scene_root_node)
                if target is Node2D
                else DreamRiggerPart3D.find_parent_part(target, true, scene_root_node)
        )
        
        if root_part != null:
            
            _bind_root_part(root_part)
            break
        pass
    
    for target: Node in targets:
        
        var parent_part := (
            DreamRiggerPart2D.find_parent_part(target, false, scene_root_node)
                if target is Node2D
                else DreamRiggerPart3D.find_parent_part(target, false, scene_root_node)
        )
        
        if parent_part is DreamRiggerPart2D || parent_part is DreamRiggerPart3D:
            
            if is_instance_valid(_pose_previewer):
                _pose_previewer.bind_part(parent_part)
            
            if is_instance_valid(_hierarchy_tree):
                _hierarchy_tree.select_part(parent_part)
            
            if is_instance_valid(_pose_browser):
                _pose_browser.bind_part(parent_part)
            
            if is_instance_valid(_part_inspector):
                _part_inspector.bind_part(parent_part)
            
            if is_instance_valid(_scratch_pad_inspector):
                _scratch_pad_inspector.bind_part(parent_part)
            
            break
    
    _is_editor_selection_changing = false
    
    pass

func _notification(what: int) -> void:
    
    match what:
        NOTIFICATION_RESIZED:
            _on_size_changed()
    
    pass

func _on_size_changed() -> void:
    
    if !is_instance_valid(_left_panel_container) || !is_instance_valid(_right_panel_container):
        return
    
    var left_panel_minimum_size := _left_panel_container.custom_minimum_size
    
    var panel_size := left_panel_minimum_size.x + INSPECTOR_COLLAPSE_WIDTH
    
    _left_panel_container.visible = size.x > panel_size
    
    pass

func _bind_root_part(part: Node) -> void:
    
    if _edit_part_root == part:
        return
    
    _unbind_root_part()
    
    if part is not DreamRiggerPart2D && part is not DreamRiggerPart3D:
        return
    
    _edit_part_root = part
    
    if is_instance_valid(_hierarchy_tree):
        _hierarchy_tree.bind_part(_edit_part_root)
    
    pass

func _unbind_root_part() -> void:
    
    if !is_instance_valid(_edit_part_root):
        return
    
    _edit_part_root = null
    _hierarchy_tree.unbind_part()
    
    pass

func _on_record_to_track_button_toggled(toggled_on: bool) -> void:
    
    _is_recording = toggled_on
    
    pass

func _on_recordable_property_changed(part: Node, property: StringName, value: Variant) -> void:
    
    if !_is_recording:
        return
    
    #This is kinda hacky, hopefully future of Godot can resolve this.
    var inspector     := EditorInterface.get_inspector()
    var edited_object := inspector.get_edited_object()
    
    EditorInterface.inspect_object(part)
    inspector.property_keyed.emit(property, value, false)
    
    EditorInterface.inspect_object(edited_object)
    
    pass
