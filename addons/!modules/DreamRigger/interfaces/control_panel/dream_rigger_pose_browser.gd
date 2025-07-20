@tool
class_name DreamRiggerPoseBrowser extends DreamRiggerGUIPanel

const EMPTY_SPRITE: Texture2D = preload("res://addons/!modules/DreamRigger/resources/empty_sprite.png")

signal recordable_property_changed(part: Node, property: StringName, value: Variant)

signal pose_resource_changed(
    part: Node,
    pose: DreamRiggerPose
)

signal sprite_selection_changed(
    part:         Node,
    first_sprite: DreamRiggerSprite,
    sprites:      Array[DreamRiggerSprite]
)

signal hovering_item_changed(
    texture: Texture2D,
    name:    String
)

#region Properties

var _binding_part: Node
var _binding_pose: DreamRiggerPose:
    get:
        
        if _binding_part is DreamRiggerPart2D || _binding_part is DreamRiggerPart3D:
            return _binding_part.pose
        
        return null

var _pose_picker_container: Control
var _pose_picker:           EditorResourcePicker
var _pose_picker_label:     Label
var _pose_list:             DreamRiggerPoseBrowserSpriteList

#endregion

#region Signal methods

func _enter_tree() -> void:
    
    super._enter_tree()
    
    _pose_picker_container = %"PosePickerContainer"
    _pose_picker_label     = %"PosePickerLabel"
    
    _pose_picker = EditorResourcePicker.new()
    _pose_picker.base_type = "DreamRiggerPose"
    
    _pose_picker_container.add_child(_pose_picker)
    
    _pose_list = %"PoseList"
    
    _pose_picker.resource_changed.connect(_on_pose_picker_resource_changed)
    
    if !_pose_list.resized.is_connected(_on_pose_list_resized):
        _pose_list.resized.connect(_on_pose_list_resized)
    
    if !_pose_list.recording_undo_redo.is_connected(_on_pose_list_recording_undo_redo):
        _pose_list.recording_undo_redo.connect(_on_pose_list_recording_undo_redo)
    
    if !_pose_list.selection_changed.is_connected(_on_pose_list_selection_changed):
        _pose_list.selection_changed.connect(_on_pose_list_selection_changed)
    
    if !_pose_list.hovering_item_changed.is_connected(_on_hovering_item_changed):
        _pose_list.hovering_item_changed.connect(_on_hovering_item_changed)
    
    refresh()
    
    pass

func _exit_tree() -> void:
    
    unbind_part()
    
    if is_instance_valid(_pose_picker):
    
        if _pose_picker.resource_selected.is_connected(_on_pose_picker_resource_changed):
            _pose_picker.resource_selected.disconnect(_on_pose_picker_resource_changed)
        
        _pose_picker.queue_free()
        
        pass
    
    if _pose_list.resized.is_connected(_on_pose_list_resized):
        _pose_list.resized.disconnect(_on_pose_list_resized)
    
    if _pose_list.recording_undo_redo.is_connected(_on_pose_list_recording_undo_redo):
        _pose_list.recording_undo_redo.disconnect(_on_pose_list_recording_undo_redo)
    
    if _pose_list.selection_changed.is_connected(_on_pose_list_selection_changed):
        _pose_list.selection_changed.disconnect(_on_pose_list_selection_changed)
    
    if _pose_list.hovering_item_changed.is_connected(_on_hovering_item_changed):
        _pose_list.hovering_item_changed.disconnect(_on_hovering_item_changed)
    
    pass

func _on_pose_picker_resource_changed(resource: Resource) -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    #FIXME: _update_part_panel에 _pose_picker.edited_resource 값을 할당하는 쪽의 주석 참고
    if _binding_pose == resource:
        return
    
    var pose: DreamRiggerPose = resource
    pose_resource_changed.emit(_binding_part, pose)
    
    pass

func _on_pose_list_resized() -> void:
    
    _pose_list.max_columns = (_pose_list.size.x - 50) / _pose_list.fixed_column_width
    
    pass

func _on_pose_list_recording_undo_redo(
    undo_redo:        EditorUndoRedoManager,
    first_selected:   int,
    selected_indexes: Array[int]) -> void:
    
    if !is_instance_valid(_binding_part) || selected_indexes.size() != 1:
        return
    
    var sprite_uid := _pose_list.index_to_uid(first_selected)
    
    undo_redo.add_do_property(_binding_part, &"pose_uid", sprite_uid)
    undo_redo.add_undo_property(_binding_part, &"pose_uid", _binding_part.pose_uid)
    
    recordable_property_changed.emit(_binding_part, &"pose_uid", sprite_uid)
    
    pass

func _on_pose_list_selection_changed(first_index: int, selected_indexes: Array[int]) -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    var first_item := _pose_list.index_to_sprite(first_index)
    
    var selected_items: Array[DreamRiggerSprite]
    selected_items.append_array(selected_indexes.map(_pose_list.index_to_sprite))
    
    sprite_selection_changed.emit(_binding_part, first_item, selected_items)
    
    pass

func _on_hovering_item_changed(texture: Texture2D, name: String) -> void:
    
    hovering_item_changed.emit(texture, name)
    
    pass

#endregion

func bind_part(part: Node) -> void:
    
    if _binding_part == part:
        return
    
    unbind_part()
    
    if part is not DreamRiggerPart2D && part is not DreamRiggerPart3D:
        return
    
    _binding_part = part
    _pose_list.bind_part(_binding_part)
    
    refresh()
    
    if !is_instance_valid(part):
        return
    
    if !part.tree_entered.is_connected(refresh):
        part.tree_entered.connect(refresh)
    
    if !part.tree_exited.is_connected(refresh):
        part.tree_exited.connect(refresh)
    
    if !part.pose_changed.is_connected(_on_part_pose_changed):
        part.pose_changed.connect(_on_part_pose_changed)
    
    if !part.pose_modified.is_connected(_on_part_pose_modified):
        part.pose_modified.connect(_on_part_pose_modified)
    
    if !part.sprite_changed.is_connected(_on_part_sprite_changed):
        part.sprite_changed.connect(_on_part_sprite_changed)
    
    pass

func unbind_part() -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    if _binding_part.tree_entered.is_connected(refresh):
        _binding_part.tree_entered.disconnect(refresh)
    
    if _binding_part.tree_exited.is_connected(refresh):
        _binding_part.tree_exited.disconnect(refresh)
    
    if _binding_part.pose_changed.is_connected(_on_part_pose_changed):
        _binding_part.pose_changed.disconnect(_on_part_pose_changed)
    
    if _binding_part.pose_modified.is_connected(_on_part_pose_modified):
        _binding_part.pose_modified.disconnect(_on_part_pose_modified)
    
    if _binding_part.sprite_changed.is_connected(_on_part_sprite_changed):
        _binding_part.sprite_changed.disconnect(_on_part_sprite_changed)
    
    _pose_list.unbind_part()
    
    _binding_part = null
    
    pass

#region Pose signal methods

func _on_part_pose_changed(pose: DreamRiggerPose) -> void:
    
    _update_pose_picker()
    
    pass

func _on_part_pose_modified(pose: DreamRiggerPose) -> void:
    
    refresh()
    
    pass

func _on_part_sprite_changed(sprite: DreamRiggerSprite) -> void:
    
    #_update_pose_selection()
    
    pass

#endregion

#region Methods

func refresh() -> void:
    
    _update_pose_picker()
    _pose_list.update_content()
    
    pass

func set_selection(first_index: int, indexes: Array[int]) -> void:
    
    _pose_list.set_selection(first_index, indexes)
    
    pass

func _update_pose_picker() -> void:
    
    if !is_instance_valid(_binding_part) || !_binding_part.is_inside_tree():
        
        _set_pose_picker_enabled(false)
        _pose_picker_label.text = "Choose part you want to edit."
        return
    
    _set_pose_picker_enabled(true)
    
    var pose := _binding_pose
    
    #FIXME: 동일 리소스를 한 번에 같이 계속 넣으면 에디터가 프리징 됨, 이슈 리포트가 필요한 지 정리 필요
    #     : [ ] 재구현 스텝 검증
    #     : [ ] 이슈 보고
    if is_instance_valid(_pose_picker) && _pose_picker.edited_resource != pose:
        _pose_picker.edited_resource = pose
    
    pass

func _set_pose_picker_enabled(state: bool) -> void:
    
    if is_instance_valid(_pose_picker):
        _pose_picker.visible = state
    
    _pose_picker_label.visible = !state
    
    pass

#endregion