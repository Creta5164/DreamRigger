## An editor [ItemList] class for managing [DreamRiggerJoint]s that given [DreamRiggerSprite]s as context.
## 
## This control class displays the [DreamRiggerJoint]s of the given [DreamRiggerSprite]s
## and provides functionality for the user to select them or perform [DreamRiggerJoint] operations
## on the contextually set [DreamRiggerSprite]s via right-clicking.
@tool
class_name DreamRiggerEditorJointItemList extends ItemList

## Enum for specifying right-click context menu action type.
enum ContextMenuAction {
    
    CREATE,     ## Create joint
    RENAME,     ## Rename joint
    DELETE      ## Delete joint
}

#region Signals

## Emits when user selects joint, also emitted when selected joint not exist after update item list.
signal joint_selected(selected_joints: Array[DreamRiggerJoint])

#endregion

#region Members

## Indicates whether the user can perform actions on this control.
@export
var enabled: bool = true:
    get:
        return enabled
    
    set(value):
        
        if !is_node_ready():
            
            ready.connect(set.bind(&"enabled", value), ConnectFlags.CONNECT_ONE_SHOT)
            return
        
        for index in item_count:
            set_item_disabled(index, !value)
        
        enabled = value
        
        pass

var _name_popup: DreamRiggerEditorLineEditPopup

#Array type = DreamRiggerJoint
var _sprite_joints: Dictionary[DreamRiggerSprite, Array]

#Array type = DreamRiggerJoint
var _joints_by_name: Dictionary[StringName, Array]

var _last_mouse_selected_name: StringName

#endregion

#region Signal methods

func _ready() -> void:
    
    if self.is_part_of_edited_scene():
        return
    
    _name_popup = DreamRiggerEditorLineEditPopup.new()
    add_child(_name_popup)
    
    empty_clicked.connect(_on_empty_clicked)
    item_clicked.connect(_on_item_clicked)
    item_selected.connect(_on_item_selected)
    
    pass

func _on_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
    
    if !enabled:
        return
    
    match mouse_button_index:
        
        MOUSE_BUTTON_LEFT:
            
            _last_mouse_selected_name = &""
            self.deselect_all()
            
            var joints: Array[DreamRiggerJoint]
            joint_selected.emit(joints)
            
            pass
        
        MOUSE_BUTTON_RIGHT:
            
            _show_context_menu()
            
            pass
        
        pass
    
    pass

func _on_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
    
    if !enabled:
        return
    
    var index_name: StringName = _joints_by_name.keys()[index]
    
    match mouse_button_index:
        
        MOUSE_BUTTON_LEFT:
            
            if _last_mouse_selected_name == index_name:
                start_rename_by_index(index)
            
            else:
                
                var joints: Array[DreamRiggerJoint]
                joints.assign(_joints_by_name[index_name])
                
                joint_selected.emit(joints)
            
            pass
        
        MOUSE_BUTTON_RIGHT:
            
            _show_context_menu()
            
            pass
    
    _last_mouse_selected_name = index_name
    
    pass

func _on_item_selected(index: int) -> void:
    
    if !enabled:
        return
    
    #TODO: Implement logics when item selected.
    
    pass

func _on_sprite_modified(sprite: DreamRiggerSprite) -> void:
    
    if !_sprite_joints.has(sprite):
        return
    
    var joints := _sprite_joints[sprite]
    
    for joint: DreamRiggerJoint in joints:
        _disconnect_joint(joint)
    
    joints.clear()
    joints.append_array(sprite.joints)
    
    for joint: DreamRiggerJoint in joints:
        _connect_joint(joint)
    
    pass

func _on_joint_modified(joint: DreamRiggerJoint) -> void:
    
    var joints: Array
    
    for joint_name in _joints_by_name:
        
        joints = _joints_by_name[joint_name]
        
        if !joints.has(joint):
            continue
        
        joints.erase(joint)
        
        if joints.size() == 0:
            _joints_by_name.erase(joint_name)
        
        pass
    
    if !_joints_by_name.has(joint.name):
        
        joints = []
        _joints_by_name[joint.name] = joints
    
    else:
        joints = _joints_by_name[joint.name]
    
    if !joints.has(joint):
        joints.append(joint)
    
    _update_item_list()
    
    pass

#endregion

#region API methods

## Sets [DreamRiggerSprite]s for handling [DreamRiggerJoint]s.
func set_sprites(sprites: Array[DreamRiggerSprite]) -> void:
    
    #Disconnect joints first
    for joints in _sprite_joints.values():
        
        for joint in joints:
            _disconnect_joint(joint)
        
        pass
    
    #And then sprites
    for sprite in _sprite_joints:
        _disconnect_sprite(sprite)
    
    _sprite_joints.clear()
    
    for sprite in sprites:
        
        if !is_instance_valid(sprite):
            continue
        
        _connect_sprite(sprite)
        
        _sprite_joints[sprite] = sprite.joints.duplicate()
        
        for joint in _sprite_joints[sprite]:
            _connect_joint(joint)
        
        pass
    
    _update_joints_by_name()
    _update_item_list()
    
    pass

func _connect_sprite(sprite: DreamRiggerSprite) -> void:
    
    if !is_instance_valid(sprite):
        return
    
    sprite.changed_ext.connect(_on_sprite_modified)
    
    pass

func _connect_joint(joint: DreamRiggerJoint) -> void:
    
    if !is_instance_valid(joint):
        return
    
    joint.changed_ext.connect(_on_joint_modified)
    
    pass

func _disconnect_sprite(sprite: DreamRiggerSprite) -> void:
    
    if !is_instance_valid(sprite):
        return
    
    sprite.changed_ext.disconnect(_on_sprite_modified)
    
    pass

func _disconnect_joint(joint: DreamRiggerJoint) -> void:
    
    if !is_instance_valid(joint):
        return
    
    joint.changed_ext.disconnect(_on_joint_modified)
    
    pass

func _update_joints_by_name() -> void:
    
    _joints_by_name.clear()
    
    for joints in _sprite_joints.values():
        
        for joint: DreamRiggerJoint in joints:
            
            if !_joints_by_name.has(joint.name):
                
                joints = []
                _joints_by_name[joint.name] = joints
            
            else:
                joints = _joints_by_name[joint.name]
            
            if joints.has(joint):
                continue
            
            joints.append(joint)
            
            pass
        
        pass
    
    pass

func _update_item_list() -> void:
    
    self.clear()
    
    var index := 0
    
    for joint_name in _joints_by_name:
        
        var joints := _joints_by_name[joint_name]
        
        if joints.size() == 1:
            self.add_item(joint_name)
        
        else:
            self.add_item("%s (%s)" % [ joint_name, joints.size() ])
        
        self.set_item_metadata(index, joint_name)
        index += 1
        
        pass
    
    _update_selection()
    
    pass

func _update_selection() -> void:
    
    self.deselect_all()
    
    var selected_index := _joints_by_name.keys().find(_last_mouse_selected_name)
    
    if selected_index == -1:
        
        var empty: Array[DreamRiggerJoint]
        joint_selected.emit(empty)
        
        return
    
    self.select(selected_index)
    
    var joints: Array[DreamRiggerJoint]
    joints.assign(_joints_by_name[_last_mouse_selected_name])
    
    joint_selected.emit(joints)
    
    pass

## Start rename to item that corresponding given [param index] to [DreamRiggerSprite]s in this control's context.
func start_rename_by_index(index: int) -> void:
    
    if index < 0 || index >= _joints_by_name.size():
        return
    
    var item_area_rect := self.get_item_rect(index)
    
    item_area_rect.position += self.get_screen_position()
    
    var joint_name: StringName = _joints_by_name.keys()[index]
    
    _name_popup.show_context(
        item_area_rect,
        joint_name,
        _on_rename_popup_submitted.bind(joint_name)
    )
    
    pass

func _on_rename_popup_submitted(value: String, previous: StringName) -> void:
    
    if value.is_empty() || !_joints_by_name.has(previous):
        return
    
    var is_joint_name_already_exist: bool
    
    var ignored_sprites: Array[DreamRiggerSprite]
    
    var ignored_joints: Array[DreamRiggerJoint]
    var target_joints:  Array[DreamRiggerJoint]
    
    var target_joint: DreamRiggerJoint
    
    for sprite in _sprite_joints:
        
        is_joint_name_already_exist = false
        
        target_joint = null
        
        for joint in sprite.joints:
            
            if joint.name == value:
                is_joint_name_already_exist = true
            
            elif joint.name == previous:
                target_joint = joint
            
            pass
        
        if target_joint == null:
            continue
        
        if is_joint_name_already_exist:
            
            ignored_sprites.append(sprite)
            ignored_joints.append(target_joint)
            continue
        
        #NOTE: This is because joint is Resource so it's for avoiding possible scenario
        #    : about same joint that assigned in multiple sprites in context.
        if ignored_joints.has(target_joint):
            
            ignored_sprites.append(sprite)
            continue
        
        target_joints.append(target_joint)
        pass
    
    if ignored_sprites.size() > 0:
        
        var toaster := EditorInterface.get_editor_toaster()
        
        for ignored_sprite in ignored_sprites:
            
            toaster.push_toast(
                "[Dream Rigger] Rename joint failed : '%s' is already exist in sprite '%s'."
                    % [ value, ignored_sprite.name ],
                EditorToaster.SEVERITY_ERROR
            )
            
            pass
        
        pass
    
    var undo_redo := EditorInterface.get_editor_undo_redo()
    
    undo_redo.create_action(
        "Rename joint name(s)",
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    for joint in target_joints:
        
        undo_redo.add_do_property(joint, &"name", value)
        undo_redo.add_undo_property(joint, &"name", joint.name)
        
        pass
    
    undo_redo.commit_action()
    
    pass

## Delete [DreamRiggerJoint] item that corresponding given [param index] to [DreamRiggerSprite]s in this control's context.
func delete_by_index(index: int) -> void:
    
    if index < 0 || index >= _joints_by_name.size():
        return
    
    var target_name: StringName = _joints_by_name.keys()[index]
    
    var undo_redo := EditorInterface.get_editor_undo_redo()
    
    undo_redo.create_action(
        "Delete joint '%s' to sprite(s)" % target_name,
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    for sprite in _sprite_joints:
        
        var joint_index := sprite._get_joint_index(target_name)
        
        if joint_index == -1:
            continue
        
        undo_redo.add_do_method(
            sprite,
            &"_remove_joint_at",
            joint_index
        )
        
        undo_redo.add_undo_method(
            sprite,
            &"_add_joint_manually",
            sprite.joints[joint_index],
            joint_index
        )
        pass
    
    undo_redo.add_do_method(self, &"call_deferred", &"_update_joints_by_name")
    undo_redo.add_do_method(self, &"call_deferred", &"_update_item_list")
    
    undo_redo.add_undo_method(self, &"call_deferred", &"_update_joints_by_name")
    undo_redo.add_undo_method(self, &"call_deferred", &"_update_item_list")
    
    undo_redo.commit_action()
    
    pass

#region Context menu methods

func _show_context_menu() -> void:
    
    await get_tree().process_frame
    
    var popup := PopupMenu.new()
    EditorInterface.get_base_control().add_child(popup)
    
    var available_joint_children := _get_available_joint_children()
    
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
    
    var selected_indexes := get_selected_items()
    
    if selected_indexes.size() > 0:
        
        popup.add_icon_item(
            get_theme_icon("Rename", "EditorIcons"),
            "Rename",
            ContextMenuAction.RENAME
        )
        
        popup.add_icon_item(
            get_theme_icon("Remove", "EditorIcons"),
            "Delete",
            ContextMenuAction.DELETE
        )
    
    var mouse_position := get_local_mouse_position()
    
    for selected_index in selected_indexes:
        
        var item_area_rect := self.get_item_rect(selected_index)
        item_area_rect.position += self.get_screen_position()
        
        if item_area_rect.has_point(mouse_position):
            
            popup.add_icon_item(
                get_theme_icon("Remove", "EditorIcons"),
                "Delete %s joints(s)" % [ selected_indexes.size() ],
                ContextMenuAction.DELETE
            )
            
            break
        
        pass
    
    popup.id_pressed.connect(_on_context_menu_selected)
    popup.close_requested.connect(popup.queue_free)
    
    popup.position = get_screen_transform() * get_local_mouse_position()
    popup.show()
    
    queue_redraw()
    
    pass

func _get_available_joint_children() -> Array[Node]:
    
    var result: Array[Node]
    
    var context := DreamRiggerEditor.get_context()
    
    if context.part_nodes.size() == 0:
        return result
    
    var first_node := context.part_nodes.front()
    result.assign(first_node.get_children())
    
    if _sprite_joints.size() == 0:
        return result
    
    for node_index in range(result.size() - 1, -1, -1):
        
        if result.size() == 0:
            return result
        
        var predicate_node := result[node_index]
        
        var joint_match_count := 0
        
        for joints: Array in _sprite_joints.values():
            
            for joint: DreamRiggerJoint in joints:
                
                if predicate_node.name == joint.name:
                    
                    joint_match_count += 1
                    break
                
                pass
            
            pass
        
        if joint_match_count == _sprite_joints.size():
            result.remove_at(node_index)
        
        pass
    
    return result

func _on_child_joint_add_selected(child_index: int) -> void:
    
    var context := DreamRiggerEditor.get_context()
    
    if context.part_nodes.size() == 0:
        return
    
    var target_node: Node = context.part_nodes.front().get_child(child_index)
    
    if !is_instance_valid(target_node):
        return
    
    var undo_redo := EditorInterface.get_editor_undo_redo()
    
    undo_redo.create_action(
        "Create joint from %s to sprite(s)" % target_node.name,
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    var toaster := EditorInterface.get_editor_toaster()
    
    for sprite: DreamRiggerSprite in _sprite_joints:
        
        if !is_instance_valid(sprite):
            continue
        
        var has_same_named_joint := false
        
        for joint: DreamRiggerJoint in sprite.joints:
        
            if joint.name == target_node.name:
                
                has_same_named_joint = true
                break
            
            pass
        
        if has_same_named_joint:
            
            toaster.push_toast(
                "[Dream Rigger] Create joint from child node : Ignored to create '%s' in sprite '%s' because it's already exist."
                    % [ target_node.name, sprite.name ],
                EditorToaster.SEVERITY_INFO
            )
            continue
        
        var created_joint := DreamRiggerJoint.new()
        created_joint.name = target_node.name
        
        undo_redo.add_do_method(
            sprite,
            &"_add_joint_manually",
            created_joint,
            sprite.joints.size()
        )
        
        undo_redo.add_undo_method(
            sprite,
            &"_remove_joint_at",
            sprite.joints.size()
        )
        pass
    
    undo_redo.add_do_method(self, &"call_deferred", &"_update_joints_by_name")
    undo_redo.add_do_method(self, &"call_deferred", &"_update_item_list")
    
    undo_redo.add_undo_method(self, &"call_deferred", &"_update_joints_by_name")
    undo_redo.add_undo_method(self, &"call_deferred", &"_update_item_list")
    
    undo_redo.commit_action()
    
    pass

func _on_context_menu_selected(id: int) -> void:
    
    var selected_index := _joints_by_name.keys().find(_last_mouse_selected_name)
    
    match id:
        ContextMenuAction.CREATE:
            
            var popup_rect := Rect2(self.get_global_mouse_position(), self.size)
            popup_rect.size.y = 10
            
            _name_popup.show_context(
                popup_rect,
                "",
                _on_create_joint_name_submitted
            )
            pass
        
        ContextMenuAction.RENAME:
            
            start_rename_by_index(selected_index)
            pass
        
        ContextMenuAction.DELETE:
            
            delete_by_index(selected_index)
            pass
    
    pass

func _on_create_joint_name_submitted(value: String) -> void:
    
    value = value.validate_node_name()
    
    if value.is_empty():
        return
    
    var context := DreamRiggerEditor.get_context()
    
    if context.part_nodes.size() == 0:
        return
    
    var undo_redo := EditorInterface.get_editor_undo_redo()
    
    undo_redo.create_action(
        "Create joint '%s' to sprite(s)" % value,
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    var toaster := EditorInterface.get_editor_toaster()
    
    for sprite: DreamRiggerSprite in _sprite_joints:
        
        if !is_instance_valid(sprite):
            continue
        
        var has_same_named_joint := false
        
        for joint: DreamRiggerJoint in sprite.joints:
        
            if joint.name == value:
                
                has_same_named_joint = true
                break
            
            pass
        
        if has_same_named_joint:
            
            toaster.push_toast(
                "[Dream Rigger] Create joint : Ignored to create '%s' in sprite '%s' because it's already exist."
                    % [ value, sprite.name ],
                EditorToaster.SEVERITY_INFO
            )
            continue
        
        var created_joint := DreamRiggerJoint.new()
        created_joint.name = value
        
        undo_redo.add_do_method(
            sprite,
            &"_add_joint_manually",
            created_joint,
            sprite.joints.size()
        )
        
        undo_redo.add_undo_method(
            sprite,
            &"_remove_joint_at",
            sprite.joints.size()
        )
        pass
    
    undo_redo.add_do_method(self, &"call_deferred", &"_update_joints_by_name")
    undo_redo.add_do_method(self, &"call_deferred", &"_update_item_list")
    
    undo_redo.add_undo_method(self, &"call_deferred", &"_update_joints_by_name")
    undo_redo.add_undo_method(self, &"call_deferred", &"_update_item_list")
    
    undo_redo.commit_action()
    
    pass

#endregion
