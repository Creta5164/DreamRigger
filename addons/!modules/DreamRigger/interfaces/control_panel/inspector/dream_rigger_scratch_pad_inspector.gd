#TODO: May need to separate these logics by per quick handles, these are too much boilerplate codes.

@tool
class_name DreamRiggerScratchPadInspector extends Control

signal recordable_property_changed(part: Node, property: StringName, value: Variant)

var _undo_redo := EditorInterface.get_editor_undo_redo()

# Part

var _part_sprite_quick_handle: DreamRiggerQuickHandle

var _part_sprite_thumbnail_left2:  TextureRect
var _part_sprite_thumbnail_left1:  TextureRect
var _part_sprite_thumbnail_main:   TextureRect
var _part_sprite_thumbnail_right1: TextureRect
var _part_sprite_thumbnail_right2: TextureRect

var _part_position_offset_quick_handle: DreamRiggerQuickHandle
var _part_rotation_z_quick_handle: DreamRiggerQuickHandle

var _flip_h_checkbox: CheckBox
var _flip_v_checkbox: CheckBox

var _part_z_layer_quick_handle: DreamRiggerQuickHandle

var _part_sprite_drag_start_index: int
var _part_rotation_z_drag_start_value: float
var _part_rotation_z_is_dragging: bool
var _part_rotation_z_drag_delta: Vector2
var _part_position_offset_drag_start_value: Vector3

# Sprite

var _sprite_joint_quick_handle: DreamRiggerQuickHandle
var _sprite_joint_list: DreamRiggerInspectorSpriteJointList

var _selected_sprite_joints: Array[DreamRiggerJoint]
var _sprite_joint_drag_start_values: Dictionary[StringName, Vector3]

var _sprite_ppu_quick_handle: DreamRiggerQuickHandle
var _sprite_offset_quick_handle: DreamRiggerQuickHandle

var _sprite_ppu_drag_start_value: float
var _sprite_offset_drag_start_value: Vector3

var _binding_part: Node
var _binding_sprite: DreamRiggerSprite

func _ready() -> void:
    
    _part_sprite_quick_handle = %"PartSpriteQuickHandle"
    
    _part_sprite_thumbnail_left2  = %"PartSpriteQuickHandleThumbnail_Left2"
    _part_sprite_thumbnail_left1  = %"PartSpriteQuickHandleThumbnail_Left1"
    _part_sprite_thumbnail_main   = %"PartSpriteQuickHandleThumbnail_Main"
    _part_sprite_thumbnail_right1 = %"PartSpriteQuickHandleThumbnail_Right1"
    _part_sprite_thumbnail_right2 = %"PartSpriteQuickHandleThumbnail_Right2"
    
    _part_position_offset_quick_handle = %"PartPositionOffsetQuickHandle"
    _part_rotation_z_quick_handle = %"PartRotationZQuickHandle"
    
    _flip_h_checkbox = %"PartFlipHCheckBox"
    _flip_v_checkbox = %"PartFlipVCheckBox"
    
    _part_z_layer_quick_handle = %"PartZLayerQuickHandle"
    
    _sprite_joint_quick_handle = %"SpriteJointQuickHandle"
    _sprite_joint_list = %"ScratchPadSpriteJointList"
    
    _sprite_ppu_quick_handle = %"SpritePPUQuickHandle"
    _sprite_offset_quick_handle = %"SpriteOffsetQuickHandle"
    
    _part_sprite_quick_handle.drag_performed.connect(_on_drag_part_sprite)
    
    _part_position_offset_quick_handle.drag_performed.connect(_on_drag_part_position_offset)
    _part_rotation_z_quick_handle.drag_performed.connect(_on_drag_part_rotation_z)
    _part_rotation_z_quick_handle.draw.connect(_on_part_rotation_z_quick_handle_draw)
    
    _flip_h_checkbox.toggled.connect(_on_flip_h_toggled)
    _flip_v_checkbox.toggled.connect(_on_flip_v_toggled)
    
    _part_z_layer_quick_handle.drag_performed.connect(_on_drag_part_z_layer)
    
    _sprite_joint_quick_handle.drag_performed.connect(_on_drag_sprite_joints)
    _sprite_joint_list.selection_changed.connect(_on_sprite_joint_selection_changed)
    
    _sprite_ppu_quick_handle.drag_performed.connect(_on_drag_sprite_ppu)
    _sprite_offset_quick_handle.drag_performed.connect(_on_drag_sprite_offset)
    
    _part_position_offset_quick_handle.gui_input.connect(_on_quick_handle_gui_input.bind(_part_position_offset_quick_handle))
    _part_rotation_z_quick_handle.gui_input.connect(_on_quick_handle_gui_input.bind(_part_rotation_z_quick_handle))
    _part_z_layer_quick_handle.gui_input.connect(_on_quick_handle_gui_input.bind(_part_z_layer_quick_handle))
    _sprite_ppu_quick_handle.gui_input.connect(_on_quick_handle_gui_input.bind(_sprite_ppu_quick_handle))
    _sprite_offset_quick_handle.gui_input.connect(_on_quick_handle_gui_input.bind(_sprite_offset_quick_handle))
    
    pass

func bind_part(part: Node) -> void:
    
    unbind_part()
    
    _binding_part = part
    _sprite_joint_list.set_part_context(part)
    
    if !is_instance_valid(_binding_part):
        return
    
    _flip_h_checkbox.disabled = false
    _flip_v_checkbox.disabled = false
    
    if !_binding_part.pose_changed.is_connected(_on_binding_part_pose_changed):
        _binding_part.pose_changed.connect(_on_binding_part_pose_changed)
    
    if !_binding_part.pose_modified.is_connected(_on_binding_part_pose_modified):
        _binding_part.pose_modified.connect(_on_binding_part_pose_modified)
    
    if !_binding_part.position_offset_changed.is_connected(_on_binding_part_position_offset_changed):
        _binding_part.position_offset_changed.connect(_on_binding_part_position_offset_changed)
    
    if !_binding_part.rotation_z_changed.is_connected(_on_binding_part_rotation_z_changed):
        _binding_part.rotation_z_changed.connect(_on_binding_part_rotation_z_changed)
    
    if !_binding_part.flip_state_changed.is_connected(_on_binding_part_flip_state_changed):
        _binding_part.flip_state_changed.connect(_on_binding_part_flip_state_changed)
    
    if !_binding_part.sprite_changed.is_connected(_on_binding_part_sprite_changed):
        _binding_part.sprite_changed.connect(_on_binding_part_sprite_changed)
    
    _update_part_sprite_thumbnails()
    _on_binding_part_position_offset_changed(_binding_part.position_offset)
    _on_binding_part_rotation_z_changed(_binding_part.rotation_z)
    _on_binding_part_sprite_changed(_binding_part.sprite)
    _on_binding_part_flip_state_changed(_binding_part.flip_h, _binding_part.flip_v)
    
    pass

func unbind_part() -> void:
    
    _flip_h_checkbox.disabled = true
    _flip_v_checkbox.disabled = true
    
    _sprite_joint_list.set_part_context(null)
    _unbind_sprite()
    
    if !is_instance_valid(_binding_part):
        return
    
    if _binding_part.pose_changed.is_connected(_on_binding_part_pose_changed):
        _binding_part.pose_changed.disconnect(_on_binding_part_pose_changed)
    
    if _binding_part.pose_modified.is_connected(_on_binding_part_pose_modified):
        _binding_part.pose_modified.disconnect(_on_binding_part_pose_modified)
    
    if _binding_part.position_offset_changed.is_connected(_on_binding_part_position_offset_changed):
        _binding_part.position_offset_changed.disconnect(_on_binding_part_position_offset_changed)
    
    if _binding_part.rotation_z_changed.is_connected(_on_binding_part_rotation_z_changed):
        _binding_part.rotation_z_changed.disconnect(_on_binding_part_rotation_z_changed)
    
    if _binding_part.flip_state_changed.is_connected(_on_binding_part_flip_state_changed):
        _binding_part.flip_state_changed.disconnect(_on_binding_part_flip_state_changed)
    
    if _binding_part.sprite_changed.is_connected(_on_binding_part_sprite_changed):
        _binding_part.sprite_changed.disconnect(_on_binding_part_sprite_changed)
    
    _update_part_sprite_thumbnails()
    _on_binding_part_position_offset_changed(Vector3.ZERO)
    _on_binding_part_rotation_z_changed(0)
    _on_binding_part_sprite_changed(null)
    _on_binding_part_flip_state_changed(false, false)
    
    _binding_part = null
    _binding_sprite = null
    
    pass

func _set_undo_redo_value(
    message:        String,
    target:         Object,
    property_name:  StringName,
    previous_value: Variant,
    new_value:      Variant,
    merge_mode:     UndoRedo.MergeMode,
    is_recordable:  bool = false) -> void:
    
    _undo_redo.create_action(message, merge_mode, EditorInterface.get_edited_scene_root())
    
    _undo_redo.add_do_property(target, property_name, new_value)
    _undo_redo.add_undo_property(target, property_name, previous_value)
    
    if is_recordable:
        recordable_property_changed.emit(target, property_name, new_value)
    
    _undo_redo.commit_action()
    
    pass

func _on_quick_handle_gui_input(event: InputEvent, sender: DreamRiggerQuickHandle) -> void:
    
    if event is not InputEventMouseButton || event.button_index != MOUSE_BUTTON_MIDDLE || !event.is_pressed():
        return
    
    match sender:
        
        _part_position_offset_quick_handle:
            
            if !is_instance_valid(_binding_part):
                return
            
            var position_offset: Vector3 = _binding_part.position_offset
            position_offset.x = 0
            position_offset.y = 0
            
            _set_undo_redo_value(
                "Reset part position_offset of %s" % _binding_part.name,
                _binding_part,
                &"position_offset",
                _binding_part.position_offset,
                position_offset,
                UndoRedo.MERGE_ENDS,
                true
            )
            
            pass
        
        _part_rotation_z_quick_handle:
            
            if !is_instance_valid(_binding_part):
                return
            
            _set_undo_redo_value(
                "Reset part rotation_z of %s" % _binding_part.name,
                _binding_part,
                &"rotation_z",
                _binding_part.position_offset,
                0,
                UndoRedo.MERGE_ENDS,
                true
            )
            
            pass
        
        _part_z_layer_quick_handle:
            
            if !is_instance_valid(_binding_part):
                return
            
            var position_offset: Vector3 = _binding_part.position_offset
            position_offset.z = 0
            
            _set_undo_redo_value(
                "Reset part Z layer (position position_offset Z) of '%s'" % _binding_part.name,
                _binding_part,
                &"position_offset",
                _binding_part.position_offset,
                position_offset,
                UndoRedo.MERGE_ENDS,
                true
            )
            
            pass
        
        _sprite_ppu_quick_handle:
            
            if !is_instance_valid(_binding_sprite):
                return
            
            _set_undo_redo_value(
                "Reset pixels per unit of sprite '%s' to 100" % _binding_sprite._display_name,
                _binding_sprite,
                &"pixels_per_unit",
                _binding_sprite.pixels_per_unit,
                100,
                UndoRedo.MERGE_ENDS
            )
            
            pass
        
        _sprite_offset_quick_handle:
            
            if !is_instance_valid(_binding_sprite):
                return
            
            _set_undo_redo_value(
                "Reset offset of sprite '%s' to zero" % _binding_sprite._display_name,
                _binding_sprite,
                &"offset",
                _binding_sprite.offset,
                Vector3.ZERO,
                UndoRedo.MERGE_ENDS
            )
            
            pass
        
        pass
    
    pass

func _on_binding_part_pose_changed(pose: DreamRiggerPose) -> void:
    
    _update_part_sprite_thumbnails()
    
    pass

func _on_binding_part_pose_modified(pose: DreamRiggerPose) -> void:
    
    _update_part_sprite_thumbnails()
    
    pass

func _on_binding_part_position_offset_changed(offset: Vector3) -> void:
    
    if !is_instance_valid(_binding_part):
        
        _part_position_offset_quick_handle.label_text  = "Position Offset\nX : -\nY : -"
        _part_z_layer_quick_handle.label_text = "Z Layer : %3d" % offset.z
        
        return
    
    _part_position_offset_quick_handle.label_text = "Position Offset\nX : %0+6.3f\nY : %0+6.3f" % [
        offset.x,
        offset.y
    ]
    
    _part_z_layer_quick_handle.label_text = "Z Layer : %3d" % offset.z
    
    pass

func _on_binding_part_rotation_z_changed(degree: float) -> void:
    
    if !is_instance_valid(_binding_part):
        
        _part_rotation_z_quick_handle.label_text = "Rotation Z\n-"
        return
    
    _part_rotation_z_quick_handle.label_text = "Rotation Z\n%0+6.3f" % degree
    
    pass

func _on_binding_part_flip_state_changed(h: bool, v: bool) -> void:
    
    _flip_h_checkbox.set_pressed_no_signal(h)
    _flip_v_checkbox.set_pressed_no_signal(v)
    
    pass

func _on_binding_part_sprite_changed(sprite: DreamRiggerSprite) -> void:
    
    if sprite == _binding_sprite:
        return
    
    _unbind_joints()
    _unbind_sprite()
    _part_sprite_quick_handle.label_text = ''
    
    if !is_instance_valid(_binding_part):
        return
    
    _binding_sprite = sprite
    
    _sprite_joint_list.bind_sprites([_binding_sprite])
    
    if !is_instance_valid(_binding_sprite):
        return
    
    if !_binding_sprite.changed.is_connected(_update_sprite_quick_handles):
        _binding_sprite.changed.connect(_update_sprite_quick_handles)
    
    _update_sprite_quick_handles()
    
    var pose: DreamRiggerPose = _binding_part.pose
    
    if !is_instance_valid(pose):
        return
    
    _part_sprite_quick_handle.label_text = "Sprite\n[%02d] %s" % [
        pose.uid_to_index(_binding_part.pose_uid),
        _binding_sprite._display_name
    ]
    
    _update_part_sprite_thumbnails()
    
    pass

func _update_part_sprite_thumbnails() -> void:
    
    if !is_instance_valid(_binding_part) || !is_instance_valid(_binding_part.pose):
        
        _part_sprite_thumbnail_left2.texture  = null
        _part_sprite_thumbnail_left1.texture  = null
        _part_sprite_thumbnail_main.texture   = null
        _part_sprite_thumbnail_right1.texture = null
        _part_sprite_thumbnail_right2.texture = null
        return
    
    var pose: DreamRiggerPose = _binding_part.pose
    var sprites_count := pose.sprites.size()
    
    var main_index := pose.uid_to_index(_binding_part.pose_uid)
    
    var left2_sprite  := pose.get_sprite(pose.index_to_uid(wrapi(main_index - 2, 0, sprites_count)))
    var left1_sprite  := pose.get_sprite(pose.index_to_uid(wrapi(main_index - 1, 0, sprites_count)))
    var main_sprite   := pose.get_sprite(pose.index_to_uid(wrapi(main_index,     0, sprites_count)))
    var right1_sprite := pose.get_sprite(pose.index_to_uid(wrapi(main_index + 1, 0, sprites_count)))
    var right2_sprite := pose.get_sprite(pose.index_to_uid(wrapi(main_index + 2, 0, sprites_count)))
    
    _part_sprite_thumbnail_left2.texture  = left2_sprite.texture  if is_instance_valid(left2_sprite)  else null
    _part_sprite_thumbnail_left1.texture  = left1_sprite.texture  if is_instance_valid(left1_sprite)  else null
    _part_sprite_thumbnail_main.texture   = main_sprite.texture   if is_instance_valid(main_sprite)   else null
    _part_sprite_thumbnail_right1.texture = right1_sprite.texture if is_instance_valid(right1_sprite) else null
    _part_sprite_thumbnail_right2.texture = right2_sprite.texture if is_instance_valid(right2_sprite) else null
    
    pass

func _unbind_sprite() -> void:
    
    if !is_instance_valid(_binding_sprite):
        return
    
    if _binding_sprite.changed.is_connected(_update_sprite_quick_handles):
        _binding_sprite.changed.disconnect(_update_sprite_quick_handles)
    
    _binding_sprite = null
    _sprite_joint_list.unbind_sprites()
    
    pass

func _update_sprite_quick_handles() -> void:
    
    _sprite_joint_quick_handle.label_text = "%s Joint(s)" % _selected_sprite_joints.size()
    
    if !is_instance_valid(_binding_sprite):
       
        _sprite_offset_quick_handle.label_text ="Offset\nX : -\nY : -"
        _sprite_ppu_quick_handle.label_text = "PPU\n-"
        
        return
    
    _sprite_offset_quick_handle.label_text = "Offset\nX : %0+6.3f\nY : %0+6.3f" % [
        _binding_sprite.offset.x,
        _binding_sprite.offset.y
    ]
    
    _sprite_ppu_quick_handle.label_text = "PPU\n%06.3f" % _binding_sprite.pixels_per_unit
    
    pass

func _on_drag_part_position_offset(phase: DreamRiggerQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    match phase:
        
        DreamRiggerQuickHandle.PHASE_BEGIN:
            
            _part_position_offset_drag_start_value = _binding_part.position_offset
            
            pass
        
        DreamRiggerQuickHandle.PHASE_MOVE:
            
            var parent_node := _binding_part.get_parent()
            
            if _binding_part is DreamRiggerPart2D:
                
                var resolved_delta := mouse_delta / 10.0
                
                if Input.is_key_pressed(KEY_CTRL):
                    resolved_delta = resolved_delta.floor()
                
                if parent_node is Node2D:
                    resolved_delta = parent_node.to_local(resolved_delta)
                
                if _binding_part._parent_flip_h: resolved_delta.x *= -1
                if _binding_part._parent_flip_v: resolved_delta.y *= -1
                
                _binding_part.position_offset = _part_position_offset_drag_start_value + Vector3(
                    resolved_delta.x,
                    resolved_delta.y,
                    0
                )
            
            elif _binding_part is DreamRiggerPart3D:
                
                var resolved_delta := Vector3(mouse_delta.x, -mouse_delta.y, 0)
                
                if Input.is_key_pressed(KEY_CTRL):
                    resolved_delta = resolved_delta.floor()
                
                if parent_node is Node3D:
                    resolved_delta = parent_node.to_local(resolved_delta)
                
                if _binding_part._parent_flip_h: resolved_delta.x *= -1
                if _binding_part._parent_flip_v: resolved_delta.y *= -1
                
                resolved_delta.z = 0
                
                _binding_part.position_offset = _part_position_offset_drag_start_value + resolved_delta
                
                pass
            
            pass
        
        DreamRiggerQuickHandle.PHASE_SUBMIT:
            
            _set_undo_redo_value(
                "Change position offset of part '%s'" % _binding_part.name,
                _binding_part,
                &"position_offset",
                _part_position_offset_drag_start_value,
                _binding_part.position_offset,
                UndoRedo.MERGE_ENDS,
                true
            )
            
            pass
        
        DreamRiggerQuickHandle.PHASE_CANCEL:
            
            _binding_part.position_offset = _part_position_offset_drag_start_value
            
            pass
    
    pass

func _on_drag_part_rotation_z(phase: DreamRiggerQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    _part_rotation_z_drag_delta = mouse_delta.limit_length(35 * 2.5)
    _part_rotation_z_quick_handle._dragging_mouse_position = _part_rotation_z_drag_delta
    
    _part_rotation_z_is_dragging = false
    
    _part_rotation_z_drag_delta /= 2.5
    
    match phase:
        
        DreamRiggerQuickHandle.PHASE_BEGIN:
            
            _part_rotation_z_drag_start_value = _binding_part.rotation_z
            
            pass
        
        DreamRiggerQuickHandle.PHASE_MOVE:
            
            _part_rotation_z_is_dragging = true
            
            var parent_node := _binding_part.get_parent()
            var resolved_rotation: float
            
            if _binding_part is DreamRiggerPart2D:
                
                var resolved_delta := Vector2(
                    _part_rotation_z_drag_delta.x,
                    _part_rotation_z_drag_delta.y
                )
                
                if parent_node is Node2D:
                    resolved_delta = parent_node.to_local(resolved_delta)
                
                if _binding_part.is_root_part:
                    if _binding_part.flip_v: resolved_delta *= -1
                
                else:
                    if _binding_part._parent_flip_h: resolved_delta.x *= -1
                    if _binding_part._parent_flip_v: resolved_delta.y *= -1
                    
                    if _binding_part.flip_v: resolved_delta *= -1
                
                resolved_rotation = rad_to_deg(
                    atan2(
                        -resolved_delta.y,
                        resolved_delta.x
                    )
                )
                
            elif _binding_part is DreamRiggerPart3D:
                
                var resolved_delta := Vector3(
                    _part_rotation_z_drag_delta.x,
                    -_part_rotation_z_drag_delta.y,
                    0
                )
                
                if parent_node is Node3D:
                    resolved_delta = parent_node.to_local(resolved_delta)
                
                if _binding_part.is_root_part:
                    if _binding_part.flip_v: resolved_delta *= -1
                
                else:
                    if _binding_part._parent_flip_h: resolved_delta.x *= -1
                    if _binding_part._parent_flip_v: resolved_delta.y *= -1
                    
                    if _binding_part.flip_v: resolved_delta *= -1
                
                resolved_rotation = rad_to_deg(
                    atan2(
                        resolved_delta.y,
                        resolved_delta.x
                    )
                )
                
                pass
            
            if Input.is_key_pressed(KEY_CTRL):
                
                resolved_rotation = snapped(resolved_rotation, 15)
                
                var drag_delta_length := _part_rotation_z_drag_delta.length()
                
                var drag_delta_degree := rad_to_deg(
                    atan2(
                        _part_rotation_z_drag_delta.y,
                        _part_rotation_z_drag_delta.x
                    )
                )
                
                drag_delta_degree = snapped(drag_delta_degree, 15)
                
                _part_rotation_z_drag_delta.x = cos(deg_to_rad(drag_delta_degree))
                _part_rotation_z_drag_delta.y = sin(deg_to_rad(drag_delta_degree))
                
                _part_rotation_z_drag_delta *= drag_delta_length
                
                pass
            
            _binding_part.rotation_z = resolved_rotation - 90
            
            pass
        
        DreamRiggerQuickHandle.PHASE_SUBMIT:
            
            _set_undo_redo_value(
                "Change rotation_z of part '%s'" % _binding_part.name,
                _binding_part,
                &"rotation_z",
                _part_rotation_z_drag_start_value,
                _binding_part.rotation_z,
                UndoRedo.MERGE_ENDS,
                true
            )
            
            pass
        
        DreamRiggerQuickHandle.PHASE_CANCEL:
            
            _binding_part.rotation_z = _part_rotation_z_drag_start_value
            
            pass
    
    _part_rotation_z_quick_handle.queue_redraw()
    
    pass

func _on_part_rotation_z_quick_handle_draw() -> void:
    
    var context := _part_rotation_z_quick_handle
    
    var center := context.size / 2
    
    context.draw_circle(center, 35, Color.DIM_GRAY)
    
    if !_part_rotation_z_is_dragging:
        return
    
    context.draw_circle(center, 5, Color.GRAY)
    
    var delta = _part_rotation_z_drag_delta.clamp(-center, center)
    
    context.draw_line(center, center + delta, Color.GRAY, 5)
    context.draw_circle(center + delta, 10, Color.GRAY)
    
    pass

func _on_flip_h_toggled(value: bool) -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    _set_undo_redo_value(
        "Toggle flip H of '%s'" % _binding_part.name,
        _binding_part,
        &"flip_h",
        _binding_part.flip_h,
        value,
        UndoRedo.MERGE_DISABLE,
        true
    )
    
    pass

func _on_flip_v_toggled(value: bool) -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    _set_undo_redo_value(
        "Toggle flip V of '%s'" % _binding_part.name,
        _binding_part,
        &"flip_v",
        _binding_part.flip_v,
        value,
        UndoRedo.MERGE_DISABLE,
        true
    )
    
    pass

func _on_drag_part_z_layer(phase: DreamRiggerQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    match phase:
        
        DreamRiggerQuickHandle.PHASE_BEGIN:
            
            _part_position_offset_drag_start_value = _binding_part.position_offset
            
            pass
        
        DreamRiggerQuickHandle.PHASE_MOVE:
            
            _binding_part.position_offset = _part_position_offset_drag_start_value + Vector3(0, 0, -floor(mouse_delta.y / 50))
            
            pass
        
        DreamRiggerQuickHandle.PHASE_SUBMIT:
            
            if _binding_part.position_offset.z == _part_position_offset_drag_start_value.z:
                
                _on_drag_part_z_layer(DreamRiggerQuickHandle.PHASE_CANCEL, Vector2.ZERO)
                return
            
            _set_undo_redo_value(
                "Change Z layer (position offset Z) of '%s'" % _binding_part.name,
                _binding_part,
                &"position_offset",
                _part_position_offset_drag_start_value,
                _binding_part.position_offset,
                UndoRedo.MERGE_ENDS,
                true
            )
            
            pass
        
        DreamRiggerQuickHandle.PHASE_CANCEL:
            
            _binding_part.position_offset = _part_position_offset_drag_start_value
            
            pass
    
    pass

func _on_drag_part_sprite(phase: DreamRiggerQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    var pose: DreamRiggerPose = _binding_part.pose
    
    if !is_instance_valid(pose):
        return
    
    match phase:
        
        DreamRiggerQuickHandle.PHASE_BEGIN:
            
            _part_sprite_drag_start_index = pose.uid_to_index(_binding_part.pose_uid)
            
            pass
        
        DreamRiggerQuickHandle.PHASE_MOVE:
            
            var scrubbing_index := wrapi(
                _part_sprite_drag_start_index - floor(mouse_delta.x / 50),
                0,
                pose.sprites.size()
            )
            
            _binding_part.pose_uid = pose.index_to_uid(scrubbing_index)
            
            pass
        
        DreamRiggerQuickHandle.PHASE_SUBMIT:
            
            var previous_uid := pose.index_to_uid(_part_sprite_drag_start_index)
            
            if previous_uid == _binding_part.pose_uid:
                
                _on_drag_part_sprite(DreamRiggerQuickHandle.PHASE_CANCEL, Vector2.ZERO)
                return
            
            _set_undo_redo_value(
                "Change pose of '%s'" % _binding_part.name,
                _binding_part,
                &"pose_uid",
                previous_uid,
                _binding_part.pose_uid,
                UndoRedo.MERGE_ENDS,
                true
            )
            
            pass
        
        DreamRiggerQuickHandle.PHASE_CANCEL:
            
            _binding_part.pose_uid = pose.index_to_uid(_part_sprite_drag_start_index)
            
            pass
    
    pass

func _on_drag_sprite_joints(phase: DreamRiggerQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    if _selected_sprite_joints.size() == 0:
        return
    
    var mouse_delta_3 := Vector3(mouse_delta.x, -mouse_delta.y, 0)
    
    match phase:
        
        DreamRiggerQuickHandle.PHASE_BEGIN:
            
            _sprite_joint_drag_start_values.clear()
            
            for joint: DreamRiggerJoint in _selected_sprite_joints:
                _sprite_joint_drag_start_values[joint.name] = joint.position
            
            pass
        
        DreamRiggerQuickHandle.PHASE_MOVE:
            
            var resolved_delta := Vector3(mouse_delta.x, mouse_delta.y, 0)
            
            if _binding_part is DreamRiggerPart2D:
                
                resolved_delta /= 10.0
                
                if Input.is_key_pressed(KEY_CTRL):
                    resolved_delta = resolved_delta.floor()
                
                var local_delta: Vector2 = _binding_part.to_local(
                    Vector2(
                        resolved_delta.x,
                        resolved_delta.y
                    )
                )
                
                resolved_delta.x = local_delta.x
                resolved_delta.y = local_delta.y
                
                if _binding_part.resolved_flip_h: resolved_delta.x *= -1
                if _binding_part.resolved_flip_v: resolved_delta.y *= -1
            
            elif _binding_part is DreamRiggerPart3D:
                
                resolved_delta.y = -resolved_delta.y
                
                if Input.is_key_pressed(KEY_CTRL):
                    resolved_delta = resolved_delta.floor()
                
                resolved_delta = _binding_part.to_local(resolved_delta)
                
                if _binding_part._parent_flip_h: resolved_delta.x *= -1
                if _binding_part._parent_flip_v: resolved_delta.y *= -1
                
                pass
            
            for joint: DreamRiggerJoint in _selected_sprite_joints:
                joint.position = _sprite_joint_drag_start_values[joint.name] + resolved_delta
            
            pass
        
        DreamRiggerQuickHandle.PHASE_SUBMIT:
            
            _undo_redo.create_action(
                "Modify joint positions of sprite '%s'" % _binding_sprite._display_name,
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            for joint: DreamRiggerJoint in _selected_sprite_joints:
                
                _undo_redo.add_do_property(joint, &"position", joint.position)
                _undo_redo.add_undo_property(joint, &"position", _sprite_joint_drag_start_values[joint.name])
            
            _undo_redo.commit_action()
            
            pass
        
        DreamRiggerQuickHandle.PHASE_CANCEL:
            
            for joint: DreamRiggerJoint in _selected_sprite_joints:
                joint.position = _sprite_joint_drag_start_values[joint.name]
            
            pass
    
    pass

func _on_sprite_joint_selection_changed(first_selected: int, selected_indexes: Array[int]) -> void:
    
    _unbind_joints()
    
    if !is_instance_valid(_binding_part) || _sprite_joint_list.item_count == 0:
        return
    
    for selected_index: int in selected_indexes:
        _selected_sprite_joints.append_array(_sprite_joint_list.to_joints(selected_index))
    
    for joint: DreamRiggerJoint in _selected_sprite_joints:
        
        if !is_instance_valid(joint):
            continue
        
        if !joint.changed.is_connected(_update_sprite_quick_handles):
            joint.changed.connect(_update_sprite_quick_handles)
    
    _update_sprite_quick_handles()
    
    pass

func _unbind_joints() -> void:
    
    for joint: DreamRiggerJoint in _selected_sprite_joints:
        
        if !is_instance_valid(joint):
            continue
        
        if joint.changed.is_connected(_update_sprite_quick_handles):
            joint.changed.disconnect(_update_sprite_quick_handles)
    
    _selected_sprite_joints.clear()
    
    _update_sprite_quick_handles()
    
    pass

func _on_drag_sprite_ppu(phase: DreamRiggerQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    if !is_instance_valid(_binding_sprite):
        return
    
    var sprite: DreamRiggerSprite = _binding_part.sprite
    
    match phase:
        
        DreamRiggerQuickHandle.PHASE_BEGIN:
            
            _sprite_ppu_drag_start_value = sprite.pixels_per_unit
            
            pass
        
        DreamRiggerQuickHandle.PHASE_MOVE:
            
            sprite.pixels_per_unit = max(
                _sprite_ppu_drag_start_value + mouse_delta.x,
                0.001
            )
            
            pass
        
        DreamRiggerQuickHandle.PHASE_SUBMIT:
            
            _set_undo_redo_value(
                "Change pixels per unit of sprite '%s' to %s" % [
                    sprite._display_name,
                    sprite.pixels_per_unit
                ],
                sprite,
                &"pixels_per_unit",
                _sprite_ppu_drag_start_value,
                sprite.pixels_per_unit,
                UndoRedo.MERGE_ENDS
            )
            
            pass
        
        DreamRiggerQuickHandle.PHASE_CANCEL:
            
            sprite.pixels_per_unit = _sprite_ppu_drag_start_value
            
            pass
    
    pass

func _on_drag_sprite_offset(phase: DreamRiggerQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    if !is_instance_valid(_binding_part) || !is_instance_valid(_binding_sprite):
        return
    
    var sprite: DreamRiggerSprite = _binding_part.sprite
    
    match phase:
        
        DreamRiggerQuickHandle.PHASE_BEGIN:
            
            _sprite_offset_drag_start_value = sprite.offset
            
            pass
        
        DreamRiggerQuickHandle.PHASE_MOVE:
            
            if _binding_part is DreamRiggerPart2D:
                
                var resolved_delta := mouse_delta / 10.0
                
                if _binding_part.resolved_flip_h: resolved_delta.x *= -1
                if _binding_part.resolved_flip_v: resolved_delta.y *= -1
                
                if Input.is_key_pressed(KEY_CTRL):
                    resolved_delta = resolved_delta.floor()
                
                resolved_delta = _binding_part.to_local(resolved_delta)
                
                sprite.offset = _sprite_offset_drag_start_value + Vector3(
                    resolved_delta.x,
                    resolved_delta.y,
                    0
                )
            
            elif _binding_part is DreamRiggerPart3D:
                
                var resolved_delta := Vector3(mouse_delta.x, -mouse_delta.y, 0)
                
                if _binding_part.resolved_flip_h: resolved_delta.x *= -1
                if _binding_part.resolved_flip_v: resolved_delta.y *= -1
                
                if Input.is_key_pressed(KEY_CTRL):
                    resolved_delta = resolved_delta.floor()
                
                resolved_delta = _binding_part.to_local(resolved_delta)
                resolved_delta.z = 0
                
                sprite.offset = _sprite_offset_drag_start_value + resolved_delta
                
                pass
            
            pass
        
        DreamRiggerQuickHandle.PHASE_SUBMIT:
            
            _set_undo_redo_value(
                "Change offset of sprite '%s' to %s" % [
                    sprite._display_name,
                    sprite.offset
                ],
                sprite,
                &"offset",
                _sprite_offset_drag_start_value,
                sprite.offset,
                UndoRedo.MERGE_ENDS
            )
            
            pass
        
        DreamRiggerQuickHandle.PHASE_CANCEL:
            
            sprite.offset = _sprite_offset_drag_start_value
            
            pass
    
    pass
