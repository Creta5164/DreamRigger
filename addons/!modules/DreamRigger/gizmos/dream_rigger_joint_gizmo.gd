@tool
class_name DreamRiggerJointGizmo extends EditorNode3DGizmo

var _undo_redo := EditorInterface.get_editor_undo_redo()

var _control_panel: DreamRiggerControlPanel:
    get:
        var editor := DreamRiggerEditor.instance
        
        if !is_instance_valid(editor):
            return null
        
        return editor.control_panel

var _part_inspector: DreamRiggerPartInspector:
    get:
        if !is_instance_valid(_control_panel):
            return null
        
        return _control_panel._part_inspector

var _sprite_inspector: DreamRiggerSpriteInspector:
    get:
        if !is_instance_valid(_control_panel):
            return null
        
        return _control_panel._sprite_inspector

var _binding_part: DreamRiggerPart3D

func _redraw() -> void:
    
    self.clear()
    
    if !is_instance_valid(_part_inspector):
        return
    
    bind_part(_part_inspector._binding_part)
    
    var node   := self.get_node_3d()
    var plugin := get_plugin()
    
    if !is_instance_valid(_binding_part):
        return
    
    var sprite := _binding_part.sprite
    
    if !is_instance_valid(sprite):
        return
    
    var resolved_joint_positions := _binding_part.resolved_joint_positions
    
    var handle_positions: PackedVector3Array = []
    var handle_ids:       PackedInt32Array   = []
    
    var selected_joints: Array[int]
    
    if is_instance_valid(_sprite_inspector._joint_list):
        selected_joints.append_array(_sprite_inspector._joint_list.get_selected_items())
    
    for joint_index: int in selected_joints:
        
        if joint_index >= sprite.joints.size():
            continue
        
        var joint := sprite.joints[joint_index]
        
        if !resolved_joint_positions.has(joint.name):
            continue
        
        var resolved_joint_position := world_to_local(part_to_world(resolved_joint_positions[joint.name]))
        
        handle_positions.append(resolved_joint_position)
        handle_ids.append(joint_index)
        
        pass
    
    if handle_positions.size() > 0:
        self.add_handles(handle_positions, plugin.get_material("joint_handle"), handle_ids)
    
    pass

#region Pose signal methods

func _on_part_pose_changed(pose: DreamRiggerPose) -> void:
    
    get_node_3d().update_gizmos()
    
    pass

func _on_part_pose_modified(pose: DreamRiggerPose) -> void:
    
    get_node_3d().update_gizmos()
    
    pass

func _on_part_sprite_changed(sprite: DreamRiggerSprite) -> void:
    
    get_node_3d().update_gizmos()
    
    pass

#endregion

func unbind_part() -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    if _binding_part.pose_changed.is_connected(_on_part_pose_changed):
        _binding_part.pose_changed.disconnect(_on_part_pose_changed)
    
    if _binding_part.pose_modified.is_connected(_on_part_pose_modified):
        _binding_part.pose_modified.disconnect(_on_part_pose_modified)
    
    if _binding_part.sprite_changed.is_connected(_on_part_sprite_changed):
        _binding_part.sprite_changed.disconnect(_on_part_sprite_changed)
    
    _binding_part = null
    
    pass

func bind_part(part: DreamRiggerPart3D) -> void:
    
    unbind_part()
    
    if !is_instance_valid(part):
        return
    
    _binding_part = part
    
    if !is_instance_valid(_binding_part):
        return
    
    if !_binding_part.pose_changed.is_connected(_on_part_pose_changed):
        _binding_part.pose_changed.connect(_on_part_pose_changed)
    
    if !_binding_part.pose_modified.is_connected(_on_part_pose_modified):
        _binding_part.pose_modified.connect(_on_part_pose_modified)
    
    if !_binding_part.sprite_changed.is_connected(_on_part_sprite_changed):
        _binding_part.sprite_changed.connect(_on_part_sprite_changed)
    
    pass

func _get_handle_name(id: int, secondary: bool) -> String:
    
    if !is_instance_valid(_binding_part):
        return ""
    
    var sprite := _binding_part.sprite
    
    if !is_instance_valid(sprite):
        return ""
    
    if id < 0 || id >= sprite.joints.size():
        return ""
    
    return sprite.joints[id].name

func local_to_world(local_position: Vector3) -> Vector3:
    return get_node_3d().global_transform * local_position

func part_to_world(part_local_position: Vector3) -> Vector3:
    return _binding_part.global_transform * part_local_position\
        if is_instance_valid(_binding_part)\
        else part_local_position

func world_to_local(world_position: Vector3) -> Vector3:
    return world_position * get_node_3d().global_transform

func _get_handle_value(id: int, secondary: bool) -> Variant:
    
    if !is_instance_valid(_binding_part):
        return Vector2.ZERO
    
    var sprite := _binding_part.sprite
    
    if !is_instance_valid(sprite):
        return Vector2.ZERO
    
    if id < 0 || id >= sprite.joints.size():
        return Vector2.ZERO
    
    return sprite.joints[id].position

func _set_handle(id: int, secondary: bool, camera: Camera3D, point: Vector2) -> void:
    
    var intersect_result = Plane(_binding_part.global_basis.z, _binding_part.global_position)\
        .intersects_ray(
            camera.project_ray_origin(point),
            camera.project_ray_normal(point)
        )
    
    if intersect_result == null:
        return
    
    var sprite := _binding_part.sprite
    
    if !is_instance_valid(sprite):
        return
    
    if id < 0 || id >= sprite.joints.size():
        return
    
    var joint := sprite.joints[id]
    
    var intersect_position: Vector3 = intersect_result * _binding_part.global_transform
    
    joint.position = sprite.to_world_space(intersect_position)
    _binding_part.resolve_positions()
    
    get_node_3d().update_gizmos()
    
    pass

func _commit_handle(
    id:        int,
    secondary: bool,
    restore:   Variant,
    cancel:    bool) -> void:
    
    var sprite := _binding_part.sprite
    
    if !is_instance_valid(sprite):
        return
    
    if id < 0 || id >= sprite.joints.size():
        return
    
    var gizmo_target_node := get_node_3d()
    
    var joint := sprite.joints[id]
    
    if cancel:
        
        joint.position = restore
        _binding_part.resolve_positions()
        gizmo_target_node.update_gizmos()
        return
    
    _undo_redo.create_action(
        "Modify joint '%s' position of '%s'" % [
            joint.name,
            _binding_part.name
        ],
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    _undo_redo.add_do_property(joint, &"position", joint.position)
    _undo_redo.add_do_method(_binding_part, &"resolve_positions")
    _undo_redo.add_do_method(gizmo_target_node, &"update_gizmos")
    
    _undo_redo.add_undo_property(joint, &"position", restore)
    _undo_redo.add_undo_method(_binding_part, &"resolve_positions")
    _undo_redo.add_undo_method(gizmo_target_node, &"update_gizmos")
    
    _undo_redo.commit_action()
    
    pass
