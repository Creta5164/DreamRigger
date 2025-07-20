@tool
class_name DreamRiggerEditorItemList extends ItemList

enum UndoRedoType {
    
    SELECTION_CHANGED,
    DESELECT_ALL
}

var undo_redo := EditorInterface.get_editor_undo_redo()

signal recording_undo_redo(
    undo_redo:        EditorUndoRedoManager,
    first_selected:   int,
    selected_indexes: Array[int])

signal selection_changed(
    first_selected:   int,
    selected_indexes: Array[int])

@export
var enable_undo_redo: bool = true

var _multi_selected_frame: int
var _first_selected_index: int = -1
var _selected_indexes:     Array[int]

func _enter_tree() -> void:
    
    if !Engine.is_editor_hint():
        return
    
    multi_selected.connect(_on_multi_selected)
    empty_clicked.connect(_on_empty_clicked)
    gui_input.connect(_on_gui_input_performed)
    
    pass

func _exit_tree() -> void:
    
    if !Engine.is_editor_hint():
        return
    
    multi_selected.disconnect(_on_multi_selected)
    empty_clicked.disconnect(_on_empty_clicked)
    gui_input.disconnect(_on_gui_input_performed)
    
    pass

func _record_undo(undo_redo: EditorUndoRedoManager) -> void:
    
    undo_redo.add_undo_method(
        self,
        &"set_selection",
        _first_selected_index,
        _selected_indexes.duplicate()
    )
    
    pass

func _on_multi_selected(index: int, selected: bool) -> void:
    
    if !is_inside_tree():
        return
    
    var current_frame: int = get_tree().get_frame()
    
    if _multi_selected_frame == current_frame:
        return
    
    _multi_selected_frame = current_frame
    
    await get_tree().process_frame
    
    var current_selected: Array[int]
    current_selected.assign(get_selected_items())
    
    var first_selected_index := _first_selected_index
    
    if current_selected.size() == 1:
        first_selected_index = index
    
    if enable_undo_redo:
        
        undo_redo.create_action(
            _get_undo_redo_name("Selection changed"),
            UndoRedo.MERGE_DISABLE,
            EditorInterface.get_edited_scene_root()
        )
        
        recording_undo_redo.emit(undo_redo, first_selected_index, current_selected)
        
        undo_redo.add_do_method(self, &"set_selection", first_selected_index, current_selected)
        _record_undo(undo_redo)
        
        undo_redo.commit_action()
    
    else:
        
        set_selection(first_selected_index, current_selected)

func is_binding_model_valid() -> bool:
    
    return false

func binding_model_size() -> int:
    
    return 0

func _on_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
    
    if mouse_button_index != MOUSE_BUTTON_LEFT:
        return
    
    if enable_undo_redo:
        
        undo_redo.create_action(
            _get_undo_redo_name("Deselect all"),
            UndoRedo.MERGE_ALL,
            EditorInterface.get_edited_scene_root()
        )
        
        var empty_array: Array[int]
        empty_array.assign([])
        
        recording_undo_redo.emit(undo_redo, -1, empty_array)
        
        undo_redo.add_do_method(self, &"set_selection", -1, empty_array)
        _record_undo(undo_redo)
        
        undo_redo.commit_action()
    
    else:
        
        set_selection(-1, [])
    
    pass

func _on_gui_input_performed(event: InputEvent) -> void:
    
    if event is InputEventMouseButton:
        if event.is_pressed() && event.button_index == MOUSE_BUTTON_RIGHT:
            _show_context_menu()
    
    pass

func _show_context_menu() -> void:
    
    pass

func update_content() -> void:
    
    if !is_binding_model_valid():
        
        self.clear()
        return
    
    super.clear()
    
    for item_index: int in binding_model_size():
        
        add_item("Item " + str(item_index))
        _on_item_added(item_index)
        pass
    
    update_selection()
    
    pass

func clear() -> void:
    
    super.clear()
    set_selection(-1, [])
    
    pass

func _on_item_added(index: int) -> void:
    
    pass

func _get_undo_redo_name(name: String) -> String:
    
    return "DreamRiggerEditorItemList : %s" % name

func to_index(item: Variant) -> int:
    
    return item as int

func to_indexes(items: Array) -> Array[int]:
    
    var mapped_items: Array[int]
    mapped_items.assign(items.map(to_index))
    
    return mapped_items

func update_selection() -> void:
    
    deselect_all()
    
    if _selected_indexes.size() == 0:
        return
    
    var has_selection: bool = false
    
    if _first_selected_index >= 0 && _first_selected_index < item_count:
        
        select(_first_selected_index, true)
        has_selection = true
        
        pass
    
    for item_index: int in item_count:
        
        if item_index == _first_selected_index:
            continue
        
        if _selected_indexes.has(item_index):
            
            select(item_index, false)
            has_selection = true
            
            pass
        
        pass
    
    if !has_selection:
        
        _first_selected_index = -1
        _selected_indexes.clear()
        
        pass
    
    pass

func select_by(first_item: Variant, items: Array) -> void:
    
    deselect_all()
    
    if !is_binding_model_valid():
        return
    
    set_selection(to_index(first_item), to_indexes(items))
    
    pass

func get_local_rect() -> Rect2:
    
    return get_rect() * get_transform()

func get_item_local_rect(index: int) -> Rect2:
    
    var rect := get_item_rect(index, false)
    rect.position.x -= get_h_scroll_bar().value
    rect.position.y -= get_v_scroll_bar().value
    
    return rect

#region Actions

func set_selection(first_index: int, indexes: Array[int]) -> void:
    
    _first_selected_index = first_index
    
    _selected_indexes.clear()
    _selected_indexes.append_array(indexes)
    
    update_selection()
    
    selection_changed.emit(first_index, indexes)
    
    pass

#endregion