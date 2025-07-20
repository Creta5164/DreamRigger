@tool
class_name DreamRiggerPartTreeItem extends TreeItem

enum MetadataColumn
{
    ICON,
    REFERENCE_PART
}

const ICON_WIDTH: int = 32
const EMPTY_SPRITE: Texture2D = preload("res://addons/!modules/DreamRigger/resources/empty_sprite.png")

enum ContextMenuAction {
    CREATE
}

var thumbnail_image:   Image
var thumbnail_texture: ImageTexture

var part: Node

var tree: DreamRiggerPartTree:
    get:
        if !is_instance_valid(tree):
            tree = get_tree()
        
        return tree

func bind_part(part: Node) -> void:
    
    unload_part()
    
    if part is not DreamRiggerPart2D && part is not DreamRiggerPart3D:
        return
    
    if !is_instance_valid(part):
        return
    
    self.part = part
    
    self.set_cell_mode(MetadataColumn.ICON, TreeItem.CELL_MODE_ICON)
    self.set_icon_max_width(MetadataColumn.ICON, ICON_WIDTH)
    self.set_selectable(MetadataColumn.ICON, false)
    _update_sprite_preview()
    
    self.set_metadata(MetadataColumn.REFERENCE_PART, part)
    self.set_text(MetadataColumn.REFERENCE_PART, part.name)
    
    _connect_signals()
    
    for child in part.get_children():
        if child is DreamRiggerPart2D || child is DreamRiggerPart3D:
            tree.add_item(child, self)
    
    part.resolve_positions()
    
    pass

func unload_part() -> void:
    
    _disconnect_signals()
    part = null
    
    _update_sprite_preview()
    
    pass

func _connect_signals() -> void:
    
    if !is_instance_valid(part):
        return
    
    part.renamed.connect(_part_renamed)
    part.tree_exiting.connect(_part_exiting_tree)
    part.child_order_changed.connect(_part_child_order_changed)
    part.child_entered_tree.connect(_part_child_entered_tree)
    part.child_exiting_tree.connect(_part_child_exiting_tree)
    part.sprite_changed.connect(_part_sprite_changed)
    part.position_resolved.connect(_part_position_resolved)
    
    pass

func _part_renamed() -> void:
    
    self.set_text(MetadataColumn.REFERENCE_PART, part.name)
    
    pass

func _part_exiting_tree() -> void:
    
    if !is_instance_valid(tree):
        return
    
    tree.remove_item(self, get_parent())
    
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

func _update_sprite_preview() -> void:
    
    thumbnail_image   = null
    thumbnail_texture = null
    
    if !is_instance_valid(part) || !is_instance_valid(part.sprite):
        
        _set_sprite_preview(null)
        return
    
    _set_sprite_preview(part.sprite.texture)
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
    
    #var region := Rect2()
    #
    #if used_rect.size.x > used_rect.size.y:
    #    
    #    region.size.x = ICON_WIDTH
    #    region.size.y = ICON_WIDTH * (float(used_rect.size.y) / float(used_rect.size.x))
    #    
    #else:
    #    
    #    region.size.x = ICON_WIDTH * (float(used_rect.size.x) / float(used_rect.size.y))
    #    region.size.y = ICON_WIDTH
    #
    #self.set_icon_region(
    #    MetadataColumn.ICON,
    #    region
    #)
    
    pass

func _part_sprite_changed(sprite: DreamRiggerSprite) -> void:
    
    _update_sprite_preview()
    pass

func _part_child_order_changed() -> void:
    
    if !is_instance_valid(tree._base_part):
        return
    
    sort_child_item()

func show_context_menu() -> void:
    
    #TODO: 컨텍스트 메뉴
    
    var popup := PopupMenu.new()
    EditorInterface.get_base_control().add_child(popup)
    
    popup.add_icon_item(
        popup.get_theme_icon("Add", "EditorIcons"),
        ""
    )
    
    popup.id_pressed.connect(_on_context_menu_selected)
    popup.close_requested.connect(popup.queue_free)
    
    popup.position = tree.get_screen_transform() * tree.get_local_mouse_position()
    popup.show()
    
    pass

func _on_context_menu_selected(id: int) -> void:
    
    
    
    pass

func sort_child_item() -> void:

    var child_count := get_child_count()
    
    if child_count == 0:
        return
    
    var sorted_items: Array[DreamRiggerPartTreeItem]
    sorted_items.assign(get_children())
    
    if sorted_items.size() > 1:
        sorted_items.sort_custom(
            func(lhs: DreamRiggerPartTreeItem, rhs: DreamRiggerPartTreeItem) -> bool:
                
                var lhs_sibling_order: int = lhs.part.get_index()\
                    if is_instance_valid(lhs) && is_instance_valid(lhs.part)\
                    else -1000
                
                var rhs_sibling_order: int = rhs.part.get_index()\
                    if is_instance_valid(rhs) && is_instance_valid(rhs.part)\
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

func get_item_by_node(node: Node) -> DreamRiggerPartTreeItem:
    
    for item: DreamRiggerPartTreeItem in get_children():
        
        if item.part == node:
            return item
    
    return null

func _part_child_entered_tree(node: Node) -> void:
    
    if node is DreamRiggerPart2D || node is DreamRiggerPart3D:
        
        if get_item_by_node(node) != null:
            return
        
        add_item(node)
    
    pass

func add_item(part: Node) -> void:
    tree.add_item(part, self)

func remove_item(item: DreamRiggerPartTreeItem) -> void:
    tree.remove_item(item, self)

func _part_child_exiting_tree(node: Node) -> void:
    
    if node is DreamRiggerPart2D || node is DreamRiggerPart3D:
        
        var item := get_item_by_node(node)
        
        if is_instance_valid(item):
            remove_item(item)
    pass

func _part_position_resolved() -> void:
    
    for item: DreamRiggerPartTreeItem in get_children():
        
        if !is_instance_valid(item):
            continue
        
    pass

func _disconnect_signals() -> void:
    
    if !is_instance_valid(part):
        return
    
    if part.renamed.is_connected(_part_renamed):
        part.renamed.disconnect(_part_renamed)
    
    if part.tree_exiting.is_connected(_part_exiting_tree):
        part.tree_exiting.disconnect(_part_exiting_tree)
    
    if part.child_order_changed.is_connected(_part_child_order_changed):
        part.child_order_changed.disconnect(_part_child_order_changed)
    
    if part.child_entered_tree.is_connected(_part_child_entered_tree):
        part.child_entered_tree.disconnect(_part_child_entered_tree)
    
    if part.child_exiting_tree.is_connected(_part_child_exiting_tree):
        part.child_exiting_tree.disconnect(_part_child_exiting_tree)
    
    if part.sprite_changed.is_connected(_part_sprite_changed):
        part.sprite_changed.disconnect(_part_sprite_changed)
    
    if part.position_resolved.is_connected(_part_position_resolved):
        part.position_resolved.disconnect(_part_position_resolved)
    
    pass
