## An editor [Tree] class for managing [DreamRiggerPart2D]s or [DreamRiggerPart3D]s as hierarchy.
## 
## This control class finds the top-level part and displays a tree hierarchy of all parts below it,
## given a node that is either a [DreamRiggerPart2D] or a [DreamRiggerPart3D],
## and provides functions for renaming and a right-click context menu.
@tool
class_name DreamRiggerEditorPartTree extends Tree

#region Constants

## Script Resource for used on it's item, see [DreamRiggerEditorPartTreeItem].
const PART_ITEM_SCRIPT := preload("./dream_rigger_editor_part_tree_item.gd")

#endregion

#region Signals

## Emits when user hovers item.
signal hovering_item_changed(part_node: Node)

#endregion

#region Members

var _root_item: DreamRiggerEditorPartTreeItem

var _rename_popup: DreamRiggerEditorLineEditPopup

var _hovering_item: DreamRiggerEditorPartTreeItem
var _last_mouse_selected_item: DreamRiggerEditorPartTreeItem

#endregion

#region Signal methods

func _init() -> void:
    
    columns = 2
    
    set_column_expand_ratio(
        DreamRiggerEditorPartTreeItem.MetadataColumn.ICON,
        0
    )
    
    set_column_custom_minimum_width(
        DreamRiggerEditorPartTreeItem.MetadataColumn.ICON,
        DreamRiggerEditorPartTreeItem.ICON_WIDTH
    )
    
    _rename_popup = DreamRiggerEditorLineEditPopup.new()
    add_child(_rename_popup)
    
    pass

func _ready() -> void:
    
    if self.is_part_of_edited_scene():
        return
    
    item_selected.connect(_on_item_selected)
    item_mouse_selected.connect(_on_item_mouse_selected)
    
    var context := DreamRiggerEditor.get_context()
    context.root_part_changed.connect(_on_root_part_context_changed)
    context.parts_changed.connect(_on_part_context_changed)
    
    pass

func _on_root_part_context_changed(root_part_node: Node) -> void:
    
    clear()
    
    _root_item = null
    _last_mouse_selected_item = null
    
    if root_part_node is not DreamRiggerPart2D && root_part_node is not DreamRiggerPart3D:
        return
    
    add_part(root_part_node)
    _on_part_context_changed(DreamRiggerEditor.get_context().part_nodes)
    
    pass

func _on_part_context_changed(parts: Array[Node]) -> void:
    
    deselect_all()
    
    if !is_instance_valid(_root_item):
        return
    
    var tree_item: DreamRiggerEditorPartTreeItem = _root_item
    
    set_block_signals(true)
    
    while is_instance_valid(tree_item):
        
        if parts.has(tree_item.part_node):
            
            set_selected(tree_item, DreamRiggerEditorPartTreeItem.MetadataColumn.REFERENCE_PART)
            break
        
        tree_item = tree_item.get_next_in_tree()
        pass
    
    set_block_signals(false)
    
    pass

func _on_item_selected() -> void:
    
    var selection := EditorInterface.get_selection()
    selection.clear()
    selection.add_node(get_selected_part())
    
    pass

func _on_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
    
    var selected_item: DreamRiggerEditorPartTreeItem = get_selected()
    
    if !is_instance_valid(selected_item):
        _last_mouse_selected_item = null
        return
    
    match mouse_button_index:
        
        MOUSE_BUTTON_LEFT:
            if _last_mouse_selected_item == selected_item:
                start_rename_part(selected_item.part_node)
            
            pass
        
        MOUSE_BUTTON_RIGHT:
            selected_item.show_context_menu()
            
            pass
    
    _last_mouse_selected_item = selected_item
    
    pass

func _input(event: InputEvent) -> void:
    
    if event is InputEventMouseMotion:
        
        #When the cursor enters the pose list, the element the mouse is hovering over will emitted via hovering_item_changed.
        if get_global_rect().has_point(event.position):
            
            var tree_item: DreamRiggerEditorPartTreeItem = get_item_at_position(get_local_mouse_position())
            
            if _hovering_item != tree_item:
                _hovering_item = tree_item
                
                if tree_item == null:
                    hovering_item_changed.emit(null)
                
                else:
                    hovering_item_changed.emit(tree_item.part_node)
                
                pass
        
        elif _hovering_item != null:
            _hovering_item = null
            hovering_item_changed.emit(null)
    
    pass

#endregion

#region API methods

## Creates [DreamRiggerEditorPartTreeItem].
func create_part(parent: DreamRiggerEditorPartTreeItem = null, index: int = -1) -> DreamRiggerEditorPartTreeItem:
    
    var tree_item := create_item(parent, index)
    tree_item.set_script(PART_ITEM_SCRIPT)
    
    return tree_item as DreamRiggerEditorPartTreeItem

#FIXME: The method name is not appropriate, it would be more appropriate to give different names to tree items and nodes depending on their purpose.
## Registers given [param part] to tree, [param part] must be [DreamRiggerPart2D] or [DreamRiggerPart3D].
func add_part(part: Node, parent: DreamRiggerEditorPartTreeItem = null) -> void:
    
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

## Removes given [param part_item], [method TreeItem.get_parent] will be used when [param parent_item] is [code]null[/code].
func remove_part(part_item: DreamRiggerEditorPartTreeItem, parent_item: DreamRiggerEditorPartTreeItem = null) -> void:
    
    if !is_instance_valid(part_item):
        return
    
    if parent_item == null:
        parent_item = part_item.get_parent()
    
    if is_instance_valid(parent_item):
        parent_item.remove_child(part_item)
    
    part_item.unbind_part()
    part_item.call_deferred(&"free")
    
    pass

## Returns currently selected [DreamRiggerEditorPartTreeItem]'s [DreamRiggerPart2D] or [DreamRiggerPart3D].
func get_selected_part() -> Node:
    
    var selected_item: DreamRiggerEditorPartTreeItem = get_selected()
    
    if !is_instance_valid(selected_item):
        return null
    
    return selected_item.part_node

## Start rename to item that corresponding given [param part].
func start_rename_part(part: Node) -> void:
    
    if !is_instance_valid(_root_item) || !is_instance_valid(part):
        return
    
    var tree_item: DreamRiggerEditorPartTreeItem = _root_item
    
    while is_instance_valid(tree_item):
        
        if tree_item.part_node == part:
            
            var item_area_rect := get_item_area_rect(tree_item, DreamRiggerEditorPartTreeItem.MetadataColumn.REFERENCE_PART)
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
    
    var undo_redo := EditorInterface.get_editor_undo_redo()
    
    undo_redo.create_action(
        "Rename part name",
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    undo_redo.add_do_property(part, &"name", value)
    undo_redo.add_undo_property(part, &"name", part.name)
    
    undo_redo.commit_action()
    pass

#endregion
