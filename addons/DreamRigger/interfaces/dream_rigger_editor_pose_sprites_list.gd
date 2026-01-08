## An editor [DreamRiggerEditorItemList] control class that helps browsing and selecting [DreamRiggerSprite]
## from [DreamRiggerPart2D]'s or [DreamRiggerPart3D]'s [DreamRiggerPose] in context.
@tool
class_name DreamRiggerEditorPoseSpritesList extends DreamRiggerEditorItemList

## Enum for handling context menu action types.
enum ContextMenuAction {
    CREATE,
    DELETE,
    DUPLICATE_BEFORE,
    DUPLICATE_AFTER
}

#region Constants

## Empty sprite.
const EMPTY_SPRITE: Texture2D = preload("../resources/empty_sprite.png")

## File extensions that support drag and drop sprite resource to create [DreamRiggerSprite].
const TEXTURE_EXTENSIONS: Array[String] = [
    "tex",
    "png",
    "bmp",
    "hdr",
    "jpg",
    "jpeg",
    "svg",
    "tga",
    "exr",
    "webp",
    "dds"
]

## Drag drop type declaration for files.
const DRAG_DROP_TYPE_FILES := "files"

## Drag drop type declaration for [DreamRiggerPose]s.
const DRAG_DROP_TYPE_POSES := "dream_rigger_poses"

## Key of pose in drag drop event data.
const DRAG_DROP_POSES_POSE := "pose"

## Key of uids in drag drop event data.
const DRAG_DROP_POSES_UIDS := "uids"

#endregion

#region Signals

## Emits when user hovers item.
signal hovering_item_changed(sprite: DreamRiggerSprite)

#endregion

#region Members

var _binding_pose: DreamRiggerPose

var _hovering_index: int = -1

var _is_dragging: bool
var _dragging_index: int = -1

var _empty_selection: Array[int]

#endregion

#region Override methods

func _get_undo_redo_name(name: String) -> String:
    
    return "DreamRigger PoseBrowser : %s" % name

func is_binding_model_valid() -> bool:
    
    return is_instance_valid(_binding_pose)

func binding_model_size() -> int:
    
    return _binding_pose.sprites.size()\
        if is_binding_model_valid()\
      else 0

func to_index(item: Variant) -> int:
    
    if !is_binding_model_valid() || item is not int:
        return -1
    
    return _binding_pose.uid_to_index(item)

func _on_item_added(index: int) -> void:
    
    if !is_binding_model_valid():
        return
    
    var uid    := _binding_pose.index_to_uid(index)
    var sprite := _binding_pose.get_sprite(uid)
    
    if !is_instance_valid(sprite):
        
        set_item_text(index, "NULL")
        set_item_icon(index, EMPTY_SPRITE)
        return
    
    var texture := sprite.texture\
        if is_instance_valid(sprite.texture)\
        else EMPTY_SPRITE
    
    var name: String = sprite._display_name
    
    if name == "UNKNOWN":
        name = "[%s]" % [ index ]
    
    else:
        name = "[%s] %s" % [ index, name ]
    
    set_item_text(index, name)
    set_item_icon(index, texture)
    
    pass

func update_selection() -> void:
    
    super.update_selection()
    
    if !is_binding_model_valid():
        return
    
    if _empty_selection.size() != 1:
        _empty_selection.resize(1)
    
    if !is_binding_model_valid():
        
        _empty_selection[0] = -1
        
        selection_changed.emit.call_deferred(-1, _empty_selection)
        
        pass
    
    var context := DreamRiggerEditor.get_context()
    
    if _selected_indexes.size() == 0:
        
        deselect_all()
        
        if context.part_nodes.size() != 1:
            return
        
        var first_part := context.part_nodes.front()
        
        if !is_instance_valid(first_part):
            return
        
        var context_pose_uid: int = first_part.get(&"pose_uid")
        
        var current_pose_index := to_index(context_pose_uid)
        
        if current_pose_index == -1:
            return
        
        _empty_selection[0] = current_pose_index
        
        select(current_pose_index, false)
        
        selection_changed.emit.call_deferred(current_pose_index, _empty_selection)
        
        return
    
    pass

#endregion

#region Signal methods

func _ready() -> void:
    
    if is_part_of_edited_scene():
        return
    
    var context := DreamRiggerEditor.get_context()
    
    context.parts_changed.connect(_on_part_context_changed)
    context.poses_changed.connect(_on_pose_context_changed)
    
    mouse_exited.connect(_on_mouse_exited)
    
    pass

func _on_mouse_exited() -> void:
    
    if _is_dragging:
        _is_dragging = false
        queue_redraw()
    
    pass

func _on_part_context_changed(part_nodes: Array[Node]) -> void:
    
    var context := DreamRiggerEditor.get_context()
    _on_pose_context_changed(context.poses)
    pass

func _on_pose_context_changed(poses: Array[DreamRiggerPose]) -> void:
    
    if is_instance_valid(_binding_pose):
        
        if _binding_pose.changed.is_connected(update_content):
            _binding_pose.changed.disconnect(update_content)
        
        for sprite: DreamRiggerSprite in _binding_pose.sprites.values():
            
            if !is_instance_valid(sprite):
                continue
            
            if sprite.changed.is_connected(update_content):
                sprite.changed.disconnect(update_content)
            
            pass
        
        pass
    
    _binding_pose = null
    
    if poses.size() > 0:
        
        var first_pose := poses.front()
        
        if poses.all(
                func(pose: DreamRiggerPose) -> bool:\
                    return pose == first_pose
            ):
            _binding_pose = first_pose
        
        pass
    
    if is_instance_valid(_binding_pose):
        
        _binding_pose.changed.connect(update_content)
        
        for sprite: DreamRiggerSprite in _binding_pose.sprites.values():
            
            if !is_instance_valid(sprite):
                continue
            
            sprite.changed.connect(update_content)
            
            pass
        
        pass
    
    _first_selected_index = -1
    _selected_indexes.clear()
    
    update_content()
    
    pass

func _input(event: InputEvent) -> void:
    
    if event is InputEventMouseMotion:
        
        #When the cursor enters the pose list, the element the mouse is hovering over will emitted via hovering_item_changed.
        if get_global_rect().has_point(event.position):
            
            var position   := get_local_mouse_position()
            var item_index := get_item_at_position(position, true)
            
            if _hovering_index != item_index:
                _hovering_index = item_index
                
                if item_index == -1:
                    hovering_item_changed.emit(null)
                
                else:
                    hovering_item_changed.emit(index_to_sprite(item_index))
                
                pass
        
        elif _hovering_index != -1:
            _hovering_index = -1
            hovering_item_changed.emit(null)
    
    pass

func _draw() -> void:
    
    if item_count == 0 || !_is_dragging:
        return
    
    var item_rect: Rect2
    var item_index := _dragging_index
    
    var is_first_item := item_index % max_columns == 0
    
    #Ignore the first column, but if it is the first item in each column
    if item_index > 0 && is_first_item:
        item_index -= 1
    
    if item_index == -1 || (item_index > 0 && is_first_item):
        
        if item_index == -1:
            item_index = item_count - 1
        
        item_rect = get_item_local_rect(item_index % item_count)
        
        item_rect.position.x += item_rect.size.x
        item_rect.size.x = 0
    
    else:
        item_rect = get_item_local_rect(item_index)
        item_rect.size.x = 0
    
    draw_rect(item_rect, Color.WHITE, false, 1)
    
    pass

func _get_drag_data(at_position: Vector2) -> Variant:
    
    if !is_binding_model_valid():
        return null
    
    var selected_pose_indexes: Array[int]
    selected_pose_indexes.assign(get_selected_items())
    
    if selected_pose_indexes.size() == 0:
        return null
    
    var items_has_point := selected_pose_indexes.any(
    func(index: int) -> bool:
        return get_item_local_rect(index).has_point(at_position)
    )
    
    if !items_has_point:
        return null
    
    var selected_poses: Array[int]
    
    selected_poses.assign(
        selected_pose_indexes.map(
    func(index: int) -> int:
        return _index_to_uid(index) as int
        )
    )
    
    return {
        "type": DRAG_DROP_TYPE_POSES,
        DRAG_DROP_POSES_UIDS: selected_poses,
        DRAG_DROP_POSES_POSE: _binding_pose
    }

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
    
    _is_dragging = false
    
    if !is_binding_model_valid():
        return false
    
    match data["type"]:
        
        DRAG_DROP_TYPE_POSES:
            
            if item_count == 0:
                return false
            
            var pose_list_rect := get_local_rect()
            pose_list_rect = pose_list_rect.grow(-10)
            
            at_position = at_position.clamp(pose_list_rect.position, pose_list_rect.position + pose_list_rect.size)
            
            _is_dragging = true
            _dragging_index = get_item_at_position(at_position, true)
            
            if _dragging_index != -1:
                
                var at_item_rect := get_item_local_rect(_dragging_index)
                
                at_item_rect.size.x = min(at_item_rect.size.x, fixed_column_width / 2)
                
                if !at_item_rect.has_point(at_position):
                    _dragging_index += 1
                    
                    if _dragging_index == item_count:
                        _dragging_index = -1
            
            queue_redraw()
            
            return true
        
        DRAG_DROP_TYPE_FILES:
            return Array(data[DRAG_DROP_TYPE_FILES]).any(_is_sprite_suitable)
        
        _:
            return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
    
    if !is_binding_model_valid():
        return
    
    _is_dragging = false
    queue_redraw()
    
    match data["type"]:
        
        DRAG_DROP_TYPE_POSES:
            
            _rearrange_pose_sprites(
                _dragging_index,
                data[DRAG_DROP_POSES_UIDS]
            )
            
        DRAG_DROP_TYPE_FILES:
            _handle_file_drop(data[DRAG_DROP_TYPE_FILES])
        
        _:
            return
    
    pass

func _handle_file_drop(files: Array[String]) -> void:
    
    var context := DreamRiggerEditor.get_context()
    
    var sprites: Array[DreamRiggerSprite] = []
    
    for file_path: String in files:
        
        var extension := file_path.get_extension().to_lower()
        
        if extension == "tres":
            if _is_dream_rigger_sprite_resource(file_path):
                sprites.append(load(file_path))
                continue
        
        if !TEXTURE_EXTENSIONS.has(extension):
            continue
        
        var resource := load(file_path)
        
        if resource is Texture2D:
            
            var sprite: DreamRiggerSprite
            
            #FIXME: May exception will arise.
            if _binding_pose.sprites.size() > 0:
                sprite = _binding_pose._get_last_valid_sprite().duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
            
            if !is_instance_valid(sprite):
                sprite = DreamRiggerSprite.new()
            
            sprite.texture         = resource
            sprite.name            = resource.resource_path.get_basename().get_file()
            sprite.pixels_per_unit = (
                1.0
                if context.current_dimension == DreamRiggerEditorContext.DimensionType.TWO
                else 100.0
            )
            
            sprites.append(sprite)
    
    if enable_undo_redo:
        
        _undo_redo.create_action(
            "Add %d sprite(s) to pose" % [ sprites.size() ],
            UndoRedo.MERGE_DISABLE,
            EditorInterface.get_edited_scene_root()
        )
        
        for sprite in sprites:
            
            var new_uid := _binding_pose._create_uid()
            
            assert(
                new_uid != 0,
                "[DreamRiggerPose] Maximum UID create iteration count reached."
            )
            
            _undo_redo.add_do_method(_binding_pose, &"_add_sprite_with_uid", new_uid, sprite)
            _undo_redo.add_undo_method(_binding_pose, &"_remove_sprite_by_uid", new_uid)
        
        _undo_redo.commit_action()
    
    else:
        
        for sprite in sprites:
            
            var new_uid := _binding_pose._create_uid()
            
            assert(
                new_uid != 0,
                "[DreamRiggerPose] Maximum UID create iteration count reached."
            )
            
            _binding_pose._add_sprite_with_uid(new_uid, sprite)
    
    pass

#endregion

#region API methods

## Returns [DreamRiggerSprite]s that corresponding selected items.
func get_selected_sprites() -> Array[DreamRiggerSprite]:
    
    if !is_binding_model_valid() || _first_selected_index == -1:
        return []
    
    var sprites: Array[DreamRiggerSprite]
    sprites.assign(_selected_indexes.map(index_to_sprite))
    
    return sprites

## Returns [DreamRiggerSprite] that corresponding given [param index] in binding model.
func index_to_sprite(index: int) -> DreamRiggerSprite:
    
    if !is_binding_model_valid():
        return null
    
    var uid    := _binding_pose.index_to_uid(index)
    var sprite := _binding_pose.get_sprite(uid)
    
    return sprite

func _index_to_uid(index: int) -> int:
    
    if !is_binding_model_valid():
        return 0
    
    return _binding_pose.index_to_uid(index)

func _rearrange_pose_sprites(destination_index: int, sprite_uids: Array[int]) -> void:
    
    if !is_binding_model_valid() || item_count == 0:
        return
    
    if destination_index == -1:
        destination_index = item_count
    
    var drop_destination_item_uid := 0
    
    if destination_index < item_count:
        drop_destination_item_uid = _index_to_uid(destination_index)
    
    var first_selected_uid := _index_to_uid(_first_selected_index)
    
    var current_sprite: DreamRiggerSprite
    var sprites: Dictionary[int, DreamRiggerSprite]
    var current_sprites := _binding_pose.sprites
    
    for current_sprite_uid: int in current_sprites:
        
        if current_sprite_uid == drop_destination_item_uid:
            
            for dropping_sprite_uid: int in sprite_uids:
                
                current_sprite = current_sprites[dropping_sprite_uid]
                sprites[dropping_sprite_uid] = current_sprite
        
        if sprite_uids.has(current_sprite_uid):
            continue
        
        current_sprite = current_sprites[current_sprite_uid]
        sprites[current_sprite_uid] = current_sprite
    
    if drop_destination_item_uid == 0:
        
        for dropping_sprite_uid: int in sprite_uids:
            
            current_sprite = current_sprites[dropping_sprite_uid]
            sprites[dropping_sprite_uid] = current_sprite
    
    if enable_undo_redo:
        
        _undo_redo.create_action(
            "Rearrange pose sprites",
            UndoRedo.MERGE_DISABLE,
            EditorInterface.get_edited_scene_root()
        )
        
        _undo_redo.add_do_property(_binding_pose, &"sprites", sprites)
        _undo_redo.add_do_method(self, &"update_content")
        _undo_redo.add_do_method(self, &"select_by", first_selected_uid, sprite_uids)
        
        _undo_redo.add_undo_property(_binding_pose, &"sprites", _binding_pose.sprites.duplicate())
        _record_undo(_undo_redo)
        
        _undo_redo.commit_action()
    
    else:
        
        _binding_pose.sprites = sprites
    
    pass

func _is_sprite_suitable(file_path: String) -> bool:
    
    var extension := file_path.get_extension().to_lower()
    
    if extension == "tres":
        
        if _is_dream_rigger_sprite_resource(file_path):
            return true
    
    return TEXTURE_EXTENSIONS.has(extension)
    
    pass

func _is_dream_rigger_sprite_resource(file_path: String) -> bool:
    
    var file_access := FileAccess.open(file_path, FileAccess.READ)
    
    if file_access == null:
        return false
    
    var definition_line := file_access.get_line()
    file_access.close()
    
    return definition_line.begins_with(
        "[gd_resource type=\"Resource\" script_class=\"DreamRiggerSprite\""
    )

func _show_context_menu() -> void:
    
    if !is_binding_model_valid():
        return
    
    await get_tree().process_frame
    
    var selected_pose_indexes: Array[int]
    selected_pose_indexes.assign(get_selected_items())
    
    var popup := PopupMenu.new()
    EditorInterface.get_base_control().add_child(popup)
    
    popup.add_icon_item(
        get_theme_icon("Add", "EditorIcons"),
        "Create blank sprite after selection",
        ContextMenuAction.CREATE
    )
    
    queue_redraw()
    
    var mouse_position := get_local_mouse_position()
    
    var items_has_point := selected_pose_indexes.any(
    func(index: int) -> bool:
        return get_item_local_rect(index).has_point(mouse_position)
    )
    
    if items_has_point:
        
        popup.add_icon_item(
            get_theme_icon("Remove", "EditorIcons"),
            "Delete %s sprite(s)" % [ selected_pose_indexes.size() ],
            ContextMenuAction.DELETE
        )
        
        var duplicate_popup := PopupMenu.new()
        popup.add_child(duplicate_popup)
        
        popup.add_submenu_node_item(
            "Duplicate %s sprite(s) at..." % [ selected_pose_indexes.size() ],
            duplicate_popup
        )
        
        duplicate_popup.id_pressed.connect(_on_context_menu_selected)
        
        duplicate_popup.add_icon_item(
            get_theme_icon("InsertBefore", "EditorIcons"),
            "Before",
            ContextMenuAction.DUPLICATE_BEFORE
        )
        
        duplicate_popup.add_icon_item(
            get_theme_icon("InsertAfter", "EditorIcons"),
            "After",
            ContextMenuAction.DUPLICATE_AFTER
        )
        
        pass
    
    popup.id_pressed.connect(_on_context_menu_selected)
    popup.close_requested.connect(popup.queue_free)
    
    popup.position = get_screen_transform() * get_local_mouse_position()
    popup.show()
    
    pass

#FIXME: Too much duplicated codes.
#FIXME: Decouple part member codes.
func _on_context_menu_selected(id: int) -> void:
    
    if !is_binding_model_valid():
        return
    
    var selected_items: Array[int]
    selected_items.assign(get_selected_items())
    
    var first_index := selected_items.min() if selected_items.size() > 0 else -1
    var last_index  := selected_items.max() if selected_items.size() > 0 else -1
    
    selected_items.assign(selected_items.map(_index_to_uid))
    
    var context := DreamRiggerEditor.get_context()
    
    match id:
        
        ContextMenuAction.CREATE:
            
            var created_sprite := DreamRiggerSprite.new()
            
            created_sprite.pixels_per_unit = (
                1.0
                if context.current_dimension == DreamRiggerEditorContext.DimensionType.TWO
                else 100.0
            )
            
            var uid := _binding_pose._create_uid()
            
            assert(
                uid != 0,
                "[DreamRiggerPose] Maximum UID create iteration count reached."
            )
            
            _undo_redo.create_action(
                "Create blank sprite to pose",
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            _undo_redo.add_do_method(
                _binding_pose,
                &"_add_sprite_at_with_uid",
                uid,
                created_sprite,
                last_index + 1
            )
            
            _undo_redo.add_do_method(
                self,
                &"select_by",
                uid,
                [ uid ]
            )
            
            _undo_redo.add_undo_method(
                _binding_pose,
                &"_remove_sprite_by_uid",
                uid
            )
            
            _record_undo(_undo_redo)
            
            _undo_redo.commit_action()
            
            pass
        
        ContextMenuAction.DELETE:
            
            if selected_items.size() == 0:
                return
            
            _undo_redo.create_action(
                "Delete %s sprite(s) from pose" % selected_items.size(),
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            var empty_array: Array[int]
            empty_array.assign([])

            _undo_redo.add_do_method(self, &"set_selection", -1, empty_array)
            
            for part in context.part_nodes:
                
                if !DreamRiggerEditor.is_part_node_valid(part):
                    continue
                
                _undo_redo.add_do_property(
                    part,
                    &"pose_uid",
                    _binding_pose.index_to_uid(last_index + 1)
                )
                
                pass
            
            for selected_item: int in selected_items:
                
                var sprite := _binding_pose.get_sprite(selected_item)
                
                _undo_redo.add_do_method(
                    _binding_pose,
                    &"_remove_sprite_by_uid",
                    selected_item
                )
                
                _undo_redo.add_undo_method(
                    _binding_pose,
                    &"_add_sprite_at_with_uid",
                    selected_item,
                    sprite,
                    _binding_pose.uid_to_index(selected_item)
                )
                
                pass
            
            for part in context.part_nodes:
                
                if !DreamRiggerEditor.is_part_node_valid(part):
                    continue
                
                _undo_redo.add_do_property(
                    part,
                    &"pose_uid",
                    part.get(&"pose_uid")
                )
                
                pass
            
            _record_undo(_undo_redo)
            
            _undo_redo.commit_action()
            
            pass
        
        ContextMenuAction.DUPLICATE_BEFORE:
            
            if selected_items.size() == 0:
                return
            
            _undo_redo.create_action(
                "Duplicate %s sprite(s) of pose before selection" % selected_items.size(),
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            selected_items.reverse()
            
            var first_selected_uid := _index_to_uid(_first_selected_index)
            
            var new_first_uid: int
            var new_uids:      Array[int]
            
            for selected_item: int in selected_items:
                
                var new_uid := _binding_pose._create_uid()
                new_uids.append(new_uid)
                
                if selected_item == first_selected_uid:
                    new_first_uid = new_uid
                
                assert(
                    new_uid != 0,
                    "[DreamRiggerPose] Maximum UID create iteration count reached."
                )
                
                var sprite := _binding_pose.get_sprite(selected_item)
                
                _undo_redo.add_do_method(
                    _binding_pose,
                    &"_add_sprite_at_with_uid",
                    new_uid,
                    sprite.duplicate_deep(Resource.DEEP_DUPLICATE_ALL),
                    first_index
                )
                
                _undo_redo.add_undo_method(
                    _binding_pose,
                    &"_remove_sprite_by_uid",
                    new_uid
                )
                
                pass
            
            _undo_redo.add_do_method(self, &"select_by", new_first_uid, new_uids)
            _record_undo(_undo_redo)
            
            _undo_redo.commit_action()
            
            pass
        
        ContextMenuAction.DUPLICATE_AFTER:
            
            if selected_items.size() == 0:
                return
            
            _undo_redo.create_action(
                "Duplicate %s sprite(s) of pose before selection" % selected_items.size(),
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            selected_items.reverse()
            
            var first_selected_uid := _index_to_uid(_first_selected_index)
            
            var new_first_uid: int
            var new_uids:      Array[int]
            
            for selected_item: int in selected_items:
                
                var new_uid := _binding_pose._create_uid()
                new_uids.append(new_uid)
                
                if selected_item == first_selected_uid:
                    new_first_uid = new_uid
                
                assert(
                    new_uid != 0,
                    "[DreamRiggerPose] Maximum UID create iteration count reached."
                )
                
                var sprite := _binding_pose.get_sprite(selected_item)
                
                _undo_redo.add_do_method(
                    _binding_pose,
                    &"_add_sprite_at_with_uid",
                    new_uid,
                    sprite.duplicate_deep(Resource.DEEP_DUPLICATE_ALL),
                    last_index + 1
                )
                
                _undo_redo.add_undo_method(
                    _binding_pose,
                    &"_remove_sprite_by_uid",
                    new_uid
                )
                
                pass
            
            _undo_redo.add_do_method(self, &"select_by", new_first_uid, new_uids)
            _record_undo(_undo_redo)
            
            _undo_redo.commit_action()
            
            pass
        
        pass
    
    pass

#endregion
