@tool
class_name DreamRiggerInspectorSpriteJointList extends DreamRiggerEditorItemList

enum ContextMenuAction {
    
    RENAME,
    CREATE,
    DELETE
}

var _rename_popup: DreamRiggerLineEditPopup

var _context_part: Node
var _binding_sprites: Array[DreamRiggerSprite]
var _sprite_joints: Dictionary[StringName, Array]   #Array = Array[DreamRiggerJoint]
var _joint_owners: Dictionary[DreamRiggerJoint, DreamRiggerSprite]

var _last_clicked_item_index: int = -1

func _init() -> void:
    
    _rename_popup = DreamRiggerLineEditPopup.new()
    add_child(_rename_popup)
    
    item_clicked.connect(_on_item_clicked)
    
    pass

func _get_undo_redo_name(name: String) -> String:
    
    return "DreamRigger Inspector joints : %s" % name

func set_part_context(part: Node) -> void:
    
    if part is not DreamRiggerPart2D && part is not DreamRiggerPart3D:
        return
    
    _context_part = part
    
    pass

func bind_sprites(sprites: Array[DreamRiggerSprite]) -> void:
    
    unbind_sprites()
    
    _binding_sprites.append_array(sprites)
    _fetch_joints()
    
    if !is_binding_model_valid():
        return
    
    for binding_sprite: DreamRiggerSprite in _binding_sprites:
        
        if !is_instance_valid(binding_sprite):
            continue
        
        if !binding_sprite.changed.is_connected(_on_sprite_changed):
            binding_sprite.changed.connect(_on_sprite_changed)
        
        pass
    
    update_content()
    
    pass

func unbind_sprites() -> void:
    
    if _binding_sprites.size() == 0:
        return
    
    _clear_joints()
    
    for binding_sprite: DreamRiggerSprite in _binding_sprites:
        
        if !is_instance_valid(binding_sprite):
            continue
        
        if binding_sprite.changed.is_connected(_on_sprite_changed):
            binding_sprite.changed.disconnect(_on_sprite_changed)
        
        pass
    
    _binding_sprites.clear()
    clear()
    
    update_content()
    
    pass

func _fetch_joints() -> void:
    
    _clear_joints()
    
    if _binding_sprites.size() == 0:
        return
    
    for binding_sprite: DreamRiggerSprite in _binding_sprites:
        
        if !is_instance_valid(binding_sprite):
            continue
        
        for joint: DreamRiggerJoint in binding_sprite.joints:
            
            var joints: Array[DreamRiggerJoint]
            
            if _sprite_joints.has(joint.name):
                joints.assign(_sprite_joints[joint.name])
            
            if !joint.changed.is_connected(_on_joint_changed):
                joint.changed.connect(_on_joint_changed)
            
            joints.append(joint)
            _sprite_joints[joint.name] = joints
            
            _joint_owners[joint] = binding_sprite
            
            pass
        
        pass
    
    update_content()
    
    pass

func _clear_joints() -> void:
    
    if _sprite_joints.size() == 0:
        return
    
    for joint_name: StringName in _sprite_joints:
        
        if _sprite_joints[joint_name] is not Array[DreamRiggerJoint]:
            
            _sprite_joints.erase(joint_name)
            continue
        
        for joint: DreamRiggerJoint in _sprite_joints[joint_name]:
            
            if joint.changed.is_connected(_on_joint_changed):
                joint.changed.disconnect(_on_joint_changed)
            
            pass
        
        pass
    
    _sprite_joints.clear()
    _joint_owners.clear()
    update_content()
    
    pass

func _on_sprite_changed() -> void:
    
    update_content()
    
    pass

func _on_joint_changed() -> void:
    
    update_content()
    
    pass

func _on_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
    
    if mouse_button_index != MOUSE_BUTTON_LEFT:
        return
    
    if _last_clicked_item_index != index:
        
        _last_clicked_item_index = index
        return
    
    
    
    pass

func is_binding_model_valid() -> bool:
    
    return _binding_sprites.size() > 0\
        && _binding_sprites.any(is_instance_valid)

func binding_model_size() -> int:
    
    if !is_binding_model_valid():
        return 0
    
    return _sprite_joints.size()

func to_joints(index: int) -> Array[DreamRiggerJoint]:
    
    if !is_binding_model_valid() || index < 0 || index >= item_count:
        
        var empty: Array[DreamRiggerJoint]
        return empty
    
    return _sprite_joints[to_name(index)]

func to_index(item: Variant) -> int:
    
    if !is_binding_model_valid() || item is not StringName:
        return -1
    
    if _sprite_joints.size() == 0:
        return -1
    
    for joint_index: int in _sprite_joints.size():
        
        if to_name(joint_index) == item:
            return joint_index
    
    return -1

func _on_item_added(index: int) -> void:
    
    var joints := to_joints(index)
    
    if joints.size() == 0:
        return
    
    var name := to_name(index)
    
    if joints.size() == 1:
        
        var joint := joints[0]
        
        set_item_text(
            index,
            "%s (%s, %s)" % [ name, joint.position.x, joint.position.y ]
        )
    
    else:
        
        set_item_text(
            index,
            "%s (%s mixed sprites)" % [ name, joints.size() ]
        )
    
    pass

func _show_context_menu() -> void:
    
    if !is_binding_model_valid():
        return
    
    await get_tree().process_frame
    
    var selected_pose_indexes: Array[int]
    selected_pose_indexes.assign(get_selected_items())
    
    var popup := PopupMenu.new()
    EditorInterface.get_base_control().add_child(popup)
    
    var available_joint_children: Array[Node]
    
    if is_instance_valid(_context_part):
        
        for child_node: Node in _context_part.get_children():
            
            if _sprite_joints.keys().any(
                func(joint_name: StringName) -> bool:
                    return joint_name == child_node.name\
                ):
                continue
            
            available_joint_children.append(child_node)
            
            pass
        
        pass
    
    if available_joint_children.size() == 0:
        
        popup.add_item("(No child nodes were found to create joint, try adding the Node as a child of the part.)")
        popup.set_item_disabled(popup.item_count - 1, true)
        
    else:
        
        var child_nodes_popup := PopupMenu.new()
        popup.add_child(child_nodes_popup)
        
        popup.add_submenu_node_item(
            "Create joint from child nodes...",
            child_nodes_popup
        )
        
        for child_node: Node in available_joint_children:
            child_nodes_popup.add_item(child_node.name, child_node.get_index())
        
        child_nodes_popup.id_pressed.connect(_on_child_joint_add_selected)
        child_nodes_popup.close_requested.connect(child_nodes_popup.queue_free)
        
        pass
    
    popup.add_icon_item(
        get_theme_icon("Add", "EditorIcons"),
        "Create joint",
        ContextMenuAction.CREATE
    )
    
    if selected_pose_indexes.size() > 0:
        
        popup.add_icon_item(
            get_theme_icon("Rename", "EditorIcons"),
            "Rename",
            ContextMenuAction.RENAME
        )
    
    var mouse_position := get_local_mouse_position()
    
    var items_has_point := selected_pose_indexes.any(
    func(index: int) -> bool:
        return get_item_local_rect(index).has_point(mouse_position)
    )
    
    if items_has_point:
        
        popup.add_icon_item(
            get_theme_icon("Remove", "EditorIcons"),
            "Delete %s joints(s)" % [ selected_pose_indexes.size() ],
            ContextMenuAction.DELETE
        )
        
        pass
    
    popup.id_pressed.connect(_on_context_menu_selected)
    popup.close_requested.connect(popup.queue_free)
    
    popup.position = get_screen_transform() * get_local_mouse_position()
    popup.show()
    
    queue_redraw()
    
    pass

func to_name(index: int) -> StringName:
    
    if !is_binding_model_valid():
        return &""
    
    if index < 0 || index >= _sprite_joints.size():
        return &""
    
    return _sprite_joints.keys()[index] as StringName

func start_rename_joint(target_joint_names: Array[StringName]) -> void:
    
    if target_joint_names.size() == 0:
        return
    
    var first_item_name: StringName
    var display_rect:    Rect2
    
    for item_index: int in item_count:
        
        var joint_name := to_name(item_index)
        
        if target_joint_names.has(joint_name):
            
            display_rect = get_item_rect(item_index)
            first_item_name = joint_name
            break
        
        pass
    
    if first_item_name.is_empty():
        return
    
    display_rect.position += get_screen_position() - Vector2.ONE * 2
    
    _rename_popup.show_context(display_rect, first_item_name, _on_rename_popup_submitted.bind(target_joint_names))
    
    pass

func _on_rename_popup_submitted(value: String, target_joint_names: Array[StringName]) -> void:
    
    if value.is_empty():
        return
    
    var excluded_sprites: Array[DreamRiggerSprite]
    var target_joints:    Array[DreamRiggerJoint]
    
    for joints: Array in _sprite_joints.values():
        
        for joint: DreamRiggerJoint in joints:
            
            var owner_sprite := _joint_owners[joint]
            
            if owner_sprite.joints.any(func(joint: DreamRiggerJoint) -> bool: return joint.name == value):
                
                if !excluded_sprites.has(owner_sprite):
                    excluded_sprites.append(owner_sprite)
                
            elif target_joint_names.has(joint.name):
                
                target_joints.append(joint)
            
            pass
        
        pass
    
    if target_joints.size() == 0:
        
        EditorInterface.get_editor_toaster().push_toast(
            "[Dream Rigger] Rename joints failed : All of selected sprites already has '%s'." % value,
            EditorToaster.SEVERITY_ERROR
        )
        
        return
    
    if excluded_sprites.size() > 0:
        
        for sprite: DreamRiggerSprite in excluded_sprites:
            
            EditorInterface.get_editor_toaster().push_toast(
                "[Dream Rigger] Renaming joint from selected sprite '%s' will ignored because it already has '%s'" % [
                    sprite._display_name,
                    value,
                ],
                EditorToaster.SEVERITY_WARNING
            )
        
        pass
    
    undo_redo.create_action(
        "Rename %s joint(s) of sprite" % target_joints.size(),
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    for joint: DreamRiggerJoint in target_joints:
        
        undo_redo.add_do_property(joint, &"name", value)
        undo_redo.add_undo_property(joint, &"name", joint.name)
        
        pass
    
    undo_redo.add_do_method(self, &"_fetch_joints")
    undo_redo.add_undo_method(self, &"_fetch_joints")
    
    undo_redo.commit_action()
    pass
    
func _on_context_menu_selected(id: int) -> void:
    
    if !is_binding_model_valid():
        return
    
    var selected_indexes: Array[int]
    selected_indexes.assign(get_selected_items())
    
    var first_index := selected_indexes.min() if selected_indexes.size() > 0 else -1
    var last_index  := selected_indexes.max() if selected_indexes.size() > 0 else -1
    
    var selected_names: Array[StringName]
    selected_names.assign(selected_indexes.map(to_name))
    
    match id:
        
        ContextMenuAction.RENAME:
            
            if _rename_popup.visible:
                return
            
            start_rename_joint(selected_names)
            
            pass
        
        ContextMenuAction.CREATE:
            
            undo_redo.create_action(
                "Create joint of %s sprite(s)" % _binding_sprites.size(),
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            var new_joint_name: StringName = "New joint %s" % get_tree().get_frame()
            
            for binding_sprite: DreamRiggerSprite in _binding_sprites:
                
                if !is_instance_valid(binding_sprite):
                    continue
                
                var created_joint := DreamRiggerJoint.new()
                created_joint.name = new_joint_name
                
                undo_redo.add_do_method(binding_sprite, &"_add_joint_manually", created_joint, binding_sprite.joints.size())
                undo_redo.add_undo_method(binding_sprite, &"_remove_joint_at", binding_sprite.joints.size())
                
                pass
            
            undo_redo.add_do_method(self, &"_fetch_joints")
            undo_redo.add_do_method(self, &"select_by", new_joint_name, [ new_joint_name ])
            
            undo_redo.add_undo_method(self, &"_fetch_joints")
            _record_undo(undo_redo)
            
            undo_redo.commit_action()
            
            pass
        
        ContextMenuAction.DELETE:
            
            if selected_names.size() == 0:
                return
            
            undo_redo.create_action(
                "Delete %s joint(s) of %s sprite(s)" % [ selected_names.size(), _binding_sprites.size() ],
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root(),
                true
            )
            
            for binding_sprite: DreamRiggerSprite in _binding_sprites:
                
                if !is_instance_valid(binding_sprite):
                    continue
                
                for selected_name: StringName in selected_names:
                    
                    var joint_index := binding_sprite._get_joint_index(selected_name)
                    
                    if joint_index == -1:
                        continue
                    
                    var joint := binding_sprite.joints[joint_index]
                    
                    undo_redo.add_do_method(
                        binding_sprite,
                        &"_remove_joint_by_name",
                        joint.name
                    )
                    
                    pass
                
                #FIXME: Hack to undoing deletion, should delete these in descending loop.
                undo_redo.add_undo_property(
                    binding_sprite,
                    &"joints",
                    binding_sprite.joints.duplicate()
                )
                
                pass
            
            undo_redo.add_do_method(self, &"_fetch_joints")
            
            var empty_array: Array[int]
            empty_array.assign([])
            undo_redo.add_do_method(self, &"set_selection", -1, empty_array)
            
            undo_redo.add_undo_method(self, &"call_deferred", &"_fetch_joints")
            _record_undo(undo_redo)
            
            undo_redo.commit_action()
            
            pass
        
    pass

func _on_child_joint_add_selected(child_index: int) -> void:
    
    if _binding_sprites.size() == 0 || !is_instance_valid(_context_part):
        return
    
    var target_node := _context_part.get_child(child_index)
    
    if !is_instance_valid(target_node):
        return
    
    undo_redo.create_action(
        "Create joint from %s to sprite" % target_node.name,
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    for binding_sprite: DreamRiggerSprite in _binding_sprites:
        
        if !is_instance_valid(binding_sprite):
            continue
        
        if binding_sprite.joints.any(func(j: DreamRiggerJoint) -> bool: return j.name == target_node.name):
            continue
        
        var created_joint := DreamRiggerJoint.new()
        created_joint.name = target_node.name
        
        undo_redo.add_do_method(
            binding_sprite,
            &"_add_joint_manually",
            created_joint,
            binding_sprite.joints.size()
        )
        
        undo_redo.add_undo_method(
            binding_sprite,
            &"_remove_joint_at",
            binding_sprite.joints.size()
        )
        pass
    
    undo_redo.add_do_method(self, &"_fetch_joints")
    undo_redo.add_do_method(self, &"select_by", target_node.name, [ target_node.name ])
    
    undo_redo.add_undo_method(self, &"_fetch_joints")
    
    _record_undo(undo_redo)
    undo_redo.commit_action()
    pass
