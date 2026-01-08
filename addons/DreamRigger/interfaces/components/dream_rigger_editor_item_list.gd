## A base class that enables data binding for [ItemList] and allows selection states to be recorded for undo operations.
## 
## The reason selection states are recorded in the undo history is that users often repeatedly
## undo and redo their choices while composing animations, periodically switching back and forth between
## previous selections—much like creating old-school flipbook animations.
## [br][br]
## This class helps support this unconscious animation workflow.
@tool
class_name DreamRiggerEditorItemList extends ItemList

#region Signals

## Emitted when recording an undo, this signal is typically emitted when a user performs an action.
signal recording_undo_redo(
    undo_redo:        EditorUndoRedoManager,
    first_selected:   int,
    selected_indexes: Array[int])

## Emitted when a selection item changes; used in situations such as when the user has not performed an action
## or when changes occur in the data model.
signal selection_changed(
    first_selected:   int,
    selected_indexes: Array[int])

#endregion

#region Members

## Enables record undo redo when user performed action.
@export
var enable_undo_redo: bool = true

var _multi_selected_frame: int
var _first_selected_index: int = -1
var _selected_indexes:     Array[int]

var _undo_redo := EditorInterface.get_editor_undo_redo()

#endregion

#region Signal methods

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
        
        _undo_redo.create_action(
            _get_undo_redo_name("Selection changed"),
            UndoRedo.MERGE_DISABLE,
            EditorInterface.get_edited_scene_root()
        )
        
        recording_undo_redo.emit(_undo_redo, first_selected_index, current_selected)
        
        _undo_redo.add_do_method(self, &"set_selection", first_selected_index, current_selected)
        _record_undo(_undo_redo)
        
        _undo_redo.commit_action()
    
    else:
        set_selection(first_selected_index, current_selected)
    
    pass

func _on_gui_input_performed(event: InputEvent) -> void:
    
    if event is InputEventMouseButton:
        if event.is_pressed() && event.button_index == MOUSE_BUTTON_RIGHT:
            _show_context_menu()
    
    pass

func _on_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
    
    if mouse_button_index != MOUSE_BUTTON_LEFT:
        return
    
    if enable_undo_redo:
        
        _undo_redo.create_action(
            _get_undo_redo_name("Deselect all"),
            UndoRedo.MERGE_ALL,
            EditorInterface.get_edited_scene_root()
        )
        
        var empty_array: Array[int]
        empty_array.assign([])
        
        recording_undo_redo.emit(_undo_redo, -1, empty_array)
        
        _undo_redo.add_do_method(self, &"set_selection", -1, empty_array)
        _record_undo(_undo_redo)
        
        _undo_redo.commit_action()
    
    else:
        
        set_selection(-1, [])
    
    pass

#endregion

#region API methods

## Clears content, mostly used for updating [ItemList] content, so this does not affect binding model.
## [br][br]
## Don't need to override this method.
func clear() -> void:
    
    super.clear()
    set_selection(-1, [])
    
    pass

## Updates [ItemList] content from it's binding model.
## [br][br]
## Don't need to override this method.
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

## Updates [ItemList]'s selection from current state.
## [br][br]
## Don't need to override this method.
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

## Updates selection state by given [param first_item] and [param items].
## [br][br]
## Not emits [signal recording_undo_redo] due this method is not performed by user.
## [br][br]
## Don't need to override this method.
func select_by(first_item: Variant, items: Array) -> void:
    
    deselect_all()
    
    if !is_binding_model_valid():
        return
    
    set_selection(to_index(first_item), to_indexes(items))
    
    pass

## Updates selection state by given [param first_index] and [param indexes].
## [br][br]
## Not emits [signal recording_undo_redo] due this method is not performed by user.
## [br][br]
## Don't need to override this method.
func set_selection(first_index: int, indexes: Array[int]) -> void:
    
    _first_selected_index = first_index
    
    _selected_indexes.clear()
    _selected_indexes.append_array(indexes)
    
    update_selection()
    
    selection_changed.emit(first_index, indexes)
    
    pass

## Indicates binding model is valid, override it to assign expression.
func is_binding_model_valid() -> bool:
    
    return false

## Indicates binding model's size, override it to assign expression.
func binding_model_size() -> int:
    
    return 0

## Returns undo redo command name with given [param name] that used for [EditorUndoRedoManager],
## override it to assign expression.
func _get_undo_redo_name(name: String) -> String:
    
    return "DreamRiggerEditorItemList : %s" % name

## Called when item being added by data model, override it to manage custom logics for item of [param index].
func _on_item_added(index: int) -> void:
    
    pass

## Called when user performed right click, override it to handle this behavior.
func _show_context_menu() -> void:
    
    pass

## Returns index from given [param item], override it to handle this behavior.
## [br][br]
## It must return [code]-1[/code] if not exist.
func to_index(item: Variant) -> int:
    
    return item as int

## Returns array of indexes from given [param items].
## [br][br]
## It uses [method to_index] to querying them, don't need to override this method.
func to_indexes(items: Array) -> Array[int]:
    
    var mapped_items: Array[int]
    mapped_items.assign(items.map(to_index))
    
    return mapped_items

#region Operation methods

func get_local_rect() -> Rect2:
    
    return get_rect() * get_transform()

func get_item_local_rect(index: int) -> Rect2:
    
    var rect := get_item_rect(index, false)
    rect.position.x -= get_h_scroll_bar().value
    rect.position.y -= get_v_scroll_bar().value
    
    return rect

func _record_undo(undo_redo: EditorUndoRedoManager) -> void:
    
    undo_redo.add_undo_method(
        self,
        &"update_content"
    )
    
    undo_redo.add_undo_method(
        self,
        &"set_selection",
        _first_selected_index,
        _selected_indexes.duplicate()
    )
    
    pass

#endregion
