## An editor [TreeItem] class that used in [DreamRiggerEditorPartTree] for capsulize binding data.
## 
## This control class is a [TreeItem] that maintains a consistent appearance within a [DreamRiggerEditorPartTree]
## and implements data binding attributes configured to observe a given [DreamRiggerPart2D] or [DreamRiggerPart3D].
@tool
class_name DreamRiggerEditorPartTreeItem extends TreeItem

## Enum that represents column type of metadata.
enum MetadataColumn
{
    ICON,               ## Icon that used for thumbnail purpose, usually uses [member DreamRiggerSprite.texture].
    REFERENCE_PART      ## Binded part node.
}

## Enum for handling context menu action types.
enum ContextMenuAction {
    CREATE      ## Create child part
}

#region Constants

## Thumbnail's width.
const ICON_WIDTH: int = 32

## Empty sprite.
const EMPTY_SPRITE: Texture2D = preload("../resources/empty_sprite.png")

#endregion

#region Members

#var thumbnail_image:   Image
#var thumbnail_texture: ImageTexture

## Binding [DreamRiggerPart2D] or [DreamRiggerPart3D].
var part_node: Node

## Typed version of [method TreeItem.get_tree].
var tree: DreamRiggerEditorPartTree:
    get:
        if !is_instance_valid(tree):
            tree = get_tree()
        
        return tree

#endregion

#region Signal methods

func _part_renamed() -> void:
    
    self.set_text(MetadataColumn.REFERENCE_PART, part_node.name)
    
    pass

func _part_exiting_tree() -> void:
    
    if !is_instance_valid(tree):
        return
    
    tree.remove_part(self, get_parent())
    
    pass

func _part_sprite_changed(sprite: DreamRiggerSprite) -> void:
    
    _update_sprite_preview()
    
    pass

func _part_child_order_changed() -> void:
    
    sort_child_item()
    
    pass

func _part_child_entered_tree(node: Node) -> void:
    
    if node is DreamRiggerPart2D || node is DreamRiggerPart3D:
        
        if get_item_by_node(node) != null:
            return
        
        add_item(node)
    
    pass

func _part_child_exiting_tree(node: Node) -> void:
    
    if node is DreamRiggerPart2D || node is DreamRiggerPart3D:
        
        var item := get_item_by_node(node)
        
        if is_instance_valid(item):
            remove_item(item)
    pass

func _part_position_resolved() -> void:
    
    for item: DreamRiggerEditorPartTreeItem in get_children():
        
        if !is_instance_valid(item):
            continue
        
    pass

#endregion

#region API methods

## Binds [DreamRiggerPart2D] or [DreamRiggerPart3D].
func bind_part(part: Node) -> void:
    
    unbind_part()
    
    if part is not DreamRiggerPart2D && part is not DreamRiggerPart3D:
        return
    
    if !is_instance_valid(part):
        return
    
    self.part_node = part
    
    self.set_cell_mode(MetadataColumn.ICON, TreeItem.CELL_MODE_ICON)
    self.set_icon_max_width(MetadataColumn.ICON, ICON_WIDTH)
    self.set_selectable(MetadataColumn.ICON, false)
    _update_sprite_preview()
    
    self.set_metadata(MetadataColumn.REFERENCE_PART, part)
    self.set_text(MetadataColumn.REFERENCE_PART, part.name)
    
    _connect_signals()
    
    for child in part.get_children():
        if child is DreamRiggerPart2D || child is DreamRiggerPart3D:
            tree.add_part(child, self)
    
    pass

func _connect_signals() -> void:
    
    if !is_instance_valid(part_node):
        return
    
    part_node.renamed.connect(_part_renamed)
    part_node.tree_exiting.connect(_part_exiting_tree)
    part_node.child_order_changed.connect(_part_child_order_changed)
    part_node.child_entered_tree.connect(_part_child_entered_tree)
    part_node.child_exiting_tree.connect(_part_child_exiting_tree)
    part_node.sprite_changed.connect(_part_sprite_changed)
    part_node.position_resolved.connect(_part_position_resolved)
    
    pass

## Unbinds currently bound [member part_node].
func unbind_part() -> void:
    
    _disconnect_signals()
    part_node = null
    
    _update_sprite_preview()
    
    pass

func _disconnect_signals() -> void:
    
    if !is_instance_valid(part_node):
        return
    
    if part_node.renamed.is_connected(_part_renamed):
        part_node.renamed.disconnect(_part_renamed)
    
    if part_node.tree_exiting.is_connected(_part_exiting_tree):
        part_node.tree_exiting.disconnect(_part_exiting_tree)
    
    if part_node.child_order_changed.is_connected(_part_child_order_changed):
        part_node.child_order_changed.disconnect(_part_child_order_changed)
    
    if part_node.child_entered_tree.is_connected(_part_child_entered_tree):
        part_node.child_entered_tree.disconnect(_part_child_entered_tree)
    
    if part_node.child_exiting_tree.is_connected(_part_child_exiting_tree):
        part_node.child_exiting_tree.disconnect(_part_child_exiting_tree)
    
    if part_node.sprite_changed.is_connected(_part_sprite_changed):
        part_node.sprite_changed.disconnect(_part_sprite_changed)
    
    if part_node.position_resolved.is_connected(_part_position_resolved):
        part_node.position_resolved.disconnect(_part_position_resolved)
    
    pass

func _update_sprite_preview() -> void:
    
    #thumbnail_image   = null
    #thumbnail_texture = null
    
    if !is_instance_valid(part_node) || !is_instance_valid(part_node.sprite):
        
        _set_sprite_preview(null)
        return
    
    _set_sprite_preview(part_node.sprite.texture)
    #FIXME: Not sure how do I optimize this
    #var image := texture.get_image()
    #
    #if image.is_compressed():
    #    image.decompress()
    #
    #var used_rect := image.get_used_rect()
    #
    #if used_rect.size == Vector2i.ZERO:
    #    
    #    self.set_icon(
    #        MetadataColumn.ICON,
    #        null
    #    )
    #    return
    #
    #thumbnail_image = Image.create(used_rect.size.x, used_rect.size.y, false, Image.FORMAT_RGBA8)
    #thumbnail_image.blit_rect(image, used_rect, Vector2i.ZERO)
    #
    #thumbnail_texture = ImageTexture.create_from_image(thumbnail_image)
    
    #var icon_region := Rect2()
    #
    #if used_rect.size.x > used_rect.size.y:
    #    
    #    icon_region.size.x = ICON_WIDTH
    #    icon_region.size.y = ICON_WIDTH * (float(used_rect.size.y) / float(used_rect.size.x))
    #    
    #else:
    #    
    #    icon_region.size.x = ICON_WIDTH * (float(used_rect.size.x) / float(used_rect.size.y))
    #    icon_region.size.y = ICON_WIDTH
    #
    #self.set_icon_region(
    #    MetadataColumn.ICON,
    #    icon_region
    #)
    
    pass

func _set_sprite_preview(sprite: Texture2D) -> void:
    
    var file_name: String = ""
    
    if is_instance_valid(sprite):
        file_name = sprite.resource_path.get_file()
    
    else:
        sprite = EMPTY_SPRITE
    
    self.set_icon(
        MetadataColumn.ICON,
        sprite
    )
    
    self.set_tooltip_text(
        MetadataColumn.ICON,
        file_name
    )
    
    pass

## Shows context menu within this as context.
func show_context_menu() -> void:
    
    var popup := PopupMenu.new()
    EditorInterface.get_base_control().add_child(popup)
    
    popup.add_icon_item(
        popup.get_theme_icon("Add", "EditorIcons"),
        "Create child part_node",
        ContextMenuAction.CREATE
    )
    
    popup.id_pressed.connect(_on_context_menu_selected)
    popup.close_requested.connect(popup.queue_free)
    
    popup.position = tree.get_screen_transform() * tree.get_local_mouse_position()
    popup.show()
    
    pass

func _on_context_menu_selected(id: int) -> void:
    
    if !is_instance_valid(part_node):
        return
    
    match id:
        
        ContextMenuAction.CREATE:
            
            if !part_node.is_inside_tree():
                return
            
            var new_part: Node = null
            
            if part_node is DreamRiggerPart2D:
                new_part = DreamRiggerPart2D.new()
            
            elif part_node is DreamRiggerPart3D:
                new_part = DreamRiggerPart3D.new()
            
            if new_part == null:
                return
            
            new_part.name = "New Part"
            
            var undo_redo := EditorInterface.get_editor_undo_redo()
            
            undo_redo.create_action(
                "Create new part_node in '%s'" % part_node.name,
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            undo_redo.add_do_reference(new_part)
            undo_redo.add_do_method(part_node, &"add_child", new_part)
            undo_redo.add_do_property(new_part, &"owner", part_node.owner)
            
            undo_redo.add_undo_method(part_node, &"remove_child", new_part)
            
            undo_redo.commit_action()
            
            pass
        
        pass
    
    pass

## Sorts child items by each binding [member part_node]'s hierarchal order.
func sort_child_item() -> void:

    var child_count := get_child_count()
    
    if child_count == 0:
        return
    
    var sorted_items: Array[DreamRiggerEditorPartTreeItem]
    sorted_items.assign(get_children())
    
    if sorted_items.size() > 1:
        sorted_items.sort_custom(
            func(lhs: DreamRiggerEditorPartTreeItem, rhs: DreamRiggerEditorPartTreeItem) -> bool:
                
                var lhs_sibling_order: int = lhs.part_node.get_index()\
                    if is_instance_valid(lhs) && is_instance_valid(lhs.part_node)\
                    else -1000
                
                var rhs_sibling_order: int = rhs.part_node.get_index()\
                    if is_instance_valid(rhs) && is_instance_valid(rhs.part_node)\
                    else -1000
                
                return lhs_sibling_order < rhs_sibling_order
        )
    
    for child_index: int in sorted_items.size():
        
        var current_item := sorted_items[child_index]
        
        current_item.sort_child_item()
        
        if child_index == sorted_items.size() - 1:
            break
        
        var next_item := sorted_items[child_index + 1]
        
        next_item.move_after(current_item)
    
    pass

## Returns corresponding [DreamRiggerEditorPartTreeItem] by given [param node].
func get_item_by_node(node: Node) -> DreamRiggerEditorPartTreeItem:
    
    for item: DreamRiggerEditorPartTreeItem in get_children():
        
        if item.part_node == node:
            return item
    
    return null

## Adds tree item with given [param part].
func add_item(part: Node) -> void:
    tree.add_part(part, self)

## Removes tree item with given [param item].
func remove_item(item: DreamRiggerEditorPartTreeItem) -> void:
    tree.remove_part(item, self)

#endregion
