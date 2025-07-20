@tool
class_name DreamRiggerPartTree extends Tree

const PART_ITEM_SCRIPT := preload("res://addons/!modules/DreamRigger/interfaces/control_panel/dream_rigger_part_tree_item.gd")

signal part_selected(part: Node)

var _undo_redo        := EditorInterface.get_editor_undo_redo()
var _editor_selection := EditorInterface.get_selection()

var _previous_mouse_selected_item: DreamRiggerPartTreeItem

var _base_part: Node
var _root_item: DreamRiggerPartTreeItem

var _rename_popup: DreamRiggerLineEditPopup

func _init() -> void:
    
    columns = 2
    
    set_column_expand_ratio(
        DreamRiggerPartTreeItem.MetadataColumn.ICON,
        0
    )
    
    set_column_custom_minimum_width(
        DreamRiggerPartTreeItem.MetadataColumn.ICON,
        DreamRiggerPartTreeItem.ICON_WIDTH
    )
    
    _rename_popup = DreamRiggerLineEditPopup.new()
    add_child(_rename_popup)
    
    pass

func _enter_tree() -> void:
    
    if !item_selected.is_connected(_on_item_selected):
        item_selected.connect(_on_item_selected)
    
    if !item_mouse_selected.is_connected(_on_item_mouse_selected):
        item_mouse_selected.connect(_on_item_mouse_selected)
    
    pass

func _exit_tree() -> void:
    
    unbind_part()
    
    if item_selected.is_connected(_on_item_selected):
        item_selected.disconnect(_on_item_selected)
    
    if item_mouse_selected.is_connected(_on_item_mouse_selected):
        item_mouse_selected.disconnect(_on_item_mouse_selected)
    
    pass

func _on_item_selected() -> void:
    
    part_selected.emit(get_selected_part())
    
    pass

func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
    
    var selected_item: DreamRiggerPartTreeItem = get_selected()
    
    if !is_instance_valid(selected_item):
        _previous_mouse_selected_item = null
        return
    
    match mouse_button_index:
        
        MOUSE_BUTTON_LEFT:
            if _previous_mouse_selected_item == selected_item:
                start_rename_part(selected_item.part)
            
            pass
        
        MOUSE_BUTTON_RIGHT:
            selected_item.show_context_menu()
            
            pass
    
    _previous_mouse_selected_item = selected_item
    
    pass

func bind_part(part: Node) -> void:
    
    unbind_part()
    
    if part is not DreamRiggerPart2D && part is not DreamRiggerPart3D:
        return
    
    _base_part = part
    
    if !is_instance_valid(part):
        return
    
    add_item(part)
    
    pass

func unbind_part() -> void:
    
    if !is_instance_valid(_root_item):
        return
    
    remove_item(_root_item)
    _previous_mouse_selected_item = null
    
    clear()
    
    _base_part = null
    
    pass

func select_part(part: Node, without_notify: bool = false) -> void:
    
    deselect_all()
    
    if !is_instance_valid(_root_item) || !is_instance_valid(part):
        return
    
    var tree_item: DreamRiggerPartTreeItem = _root_item
    
    while is_instance_valid(tree_item):
        
        if tree_item.part == part:
            
            set_selected(tree_item, DreamRiggerPartTreeItem.MetadataColumn.REFERENCE_PART)
            break
        
        tree_item = tree_item.get_next_in_tree()
        pass
    
    pass

func create_part(parent: DreamRiggerPartTreeItem = null, index: int = -1) -> DreamRiggerPartTreeItem:
    
    var tree_item := create_item(parent, index)
    tree_item.set_script(PART_ITEM_SCRIPT)
    
    return tree_item as DreamRiggerPartTreeItem

func add_item(part: Node, parent: DreamRiggerPartTreeItem = null) -> void:
    
    if !is_instance_valid(part):
        return
    
    if parent == null:
        
        if is_instance_valid(_root_item):
            return
        
        parent = create_part()
        _root_item = parent
    
    elif part.is_root_part:
        return
    
    var part_item := create_part(parent)
    part_item.bind_part(part)
    
    pass

func remove_item(part_item: DreamRiggerPartTreeItem, parent_item: DreamRiggerPartTreeItem = null) -> void:
    
    if !is_instance_valid(part_item):
        return
    
    if parent_item == null:
        parent_item = part_item.get_parent()
    
    if is_instance_valid(parent_item):
        parent_item.remove_child(part_item)
    
    part_item.unload_part()
    part_item.call_deferred(&"free")
    
    pass

func get_selected_part() -> Node:
    
    var selected_item: DreamRiggerPartTreeItem = get_selected()
    
    if !is_instance_valid(selected_item):
        return null
    
    return selected_item.part

func start_rename_part(part: Node) -> void:
    
    if !is_instance_valid(_root_item) || !is_instance_valid(part):
        return
    
    var tree_item: DreamRiggerPartTreeItem = _root_item
    
    while is_instance_valid(tree_item):
        
        if tree_item.part == part:
            
            var item_area_rect := get_item_area_rect(tree_item, DreamRiggerPartTreeItem.MetadataColumn.REFERENCE_PART)
            item_area_rect.position += get_screen_position()
            
            _rename_popup.show_context(
                item_area_rect,
                part.name,
                _on_rename_popup_submitted.bind(part)
            )
            break
        
        tree_item = tree_item.get_next_in_tree()
        pass
    
    pass

func _on_rename_popup_submitted(value: String, part: Node) -> void:
    
    if value.is_empty():
        return
    
    var neighbor_nodes := part.get_parent().get_children()
    neighbor_nodes.erase(part)
    
    if neighbor_nodes.any(func(node: Node) -> bool: return node.name == value):
        
        EditorInterface.get_editor_toaster().push_toast(
            "[Dream Rigger] Rename part node failed : '%s' is already exist in neighbor nodes." % value,
            EditorToaster.SEVERITY_ERROR
        )
        
        return
    
    _undo_redo.create_action(
        "Rename part name",
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    _undo_redo.add_do_property(part, &"name", value)
    _undo_redo.add_undo_property(part, &"name", part.name)
    
    _undo_redo.commit_action()
    pass