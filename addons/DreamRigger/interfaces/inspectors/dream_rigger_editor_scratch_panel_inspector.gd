@tool
class_name DreamRiggerEditorScratchPanelInspector extends Control

#region Members

var _undo_redo := EditorInterface.get_editor_undo_redo()

@onready var _part_position_offset_quick_handle: DreamRiggerEditorQuickHandle   = %PartPositionOffsetQuickHandle
@onready var _part_rotation_z_quick_handle:      DreamRiggerEditorQuickHandle   = %PartRotationZQuickHandle
@onready var _part_flip_h_checkbox:              CheckBox                       = %PartFlipHCheckBox
@onready var _part_flip_v_checkbox:              CheckBox                       = %PartFlipVCheckBox
@onready var _part_z_layer_quick_handle:         DreamRiggerEditorQuickHandle   = %PartZLayerQuickHandle
@onready var _sprite_joint_quick_handle:         DreamRiggerEditorQuickHandle   = %SpriteJointQuickHandle
@onready var _sprite_joint_list:                 DreamRiggerEditorJointItemList = %ScratchPadSpriteJointList
@onready var _sprite_offset_quick_handle:        DreamRiggerEditorQuickHandle   = %SpriteOffsetQuickHandle
@onready var _sprite_ppu_quick_handle:           DreamRiggerEditorQuickHandle   = %SpritePPUQuickHandle

var _part_rotation_z_drag_delta: Vector2

var _part_nodes: Array[Node]
var _sprites:    Array[DreamRiggerSprite]
var _joints:     Array[DreamRiggerJoint]

#TODO: Maybe we can use inspectors' properties directly instead of duplicating these properties.
#region Parts

var _part_position_offset: Vector2:
    get:
        var result: Vector2
        
        result.x = DreamRiggerEditorContext._get_property_or_default(_part_nodes, ^"position_offset:x", 0)
        result.y = DreamRiggerEditorContext._get_property_or_default(_part_nodes, ^"position_offset:y", 0)
        
        return result

var _part_z_layer: int:
    get:
        return DreamRiggerEditorContext._get_property_or_default(_part_nodes, ^"position_offset:z", 0)

var _part_rotation: float:
    get:
        return DreamRiggerEditorContext._get_property_or_default(_part_nodes, ^"rotation_z", 0)

var _part_flip_h: bool:
    get:
        return DreamRiggerEditorContext._get_property_or_default(_part_nodes, ^"flip_h", false)

var _part_flip_v: bool:
    get:
        return DreamRiggerEditorContext._get_property_or_default(_part_nodes, ^"flip_v", false)

#endregion

#region Sprites

var _sprite_name: StringName:
    get:
        return DreamRiggerEditorContext._get_property_or_default(_sprites, ^"name", &"")

var _sprite_offset: Vector2:
    get:
        var result: Vector2
        
        result.x = DreamRiggerEditorContext._get_property_or_default(_sprites, ^"offset:x", 0)
        result.y = DreamRiggerEditorContext._get_property_or_default(_sprites, ^"offset:y", 0)
        
        return result

var _sprite_pixels_per_unit: int:
    get:
        return DreamRiggerEditorContext._get_property_or_default(_sprites, ^"pixels_per_unit", 0)

#endregion

#region Joints

var _joint_position: Vector2:
    get:
        var result: Vector2
        
        result.x = DreamRiggerEditorContext._get_property_or_default(_joints, ^"position:x", 0)
        result.y = DreamRiggerEditorContext._get_property_or_default(_joints, ^"position:y", 0)
        
        return result

#endregion

#endregion

func _ready() -> void:
    
    if is_part_of_edited_scene():
        return
    
    var context := DreamRiggerEditor.get_context()
    
    context.parts_changed.connect(set_part_nodes)
    context.sprites_changed.connect(set_sprites)
    
    _part_position_offset_quick_handle.drag_performed.connect(_on_part_position_offset_drag_performed)
    _part_rotation_z_quick_handle.drag_performed.connect(_on_part_rotation_z_drag_performed)
    _part_rotation_z_quick_handle.draw.connect(_on_part_rotation_z_quick_handle_draw)
    
    _part_flip_h_checkbox.toggled.connect(_on_part_flip_h_toggled)
    _part_flip_v_checkbox.toggled.connect(_on_part_flip_v_toggled)
    
    _part_z_layer_quick_handle.drag_performed.connect(_on_part_z_layer_drag_performed)
    
    _sprite_joint_list.joint_selected.connect(_on_joint_list_selection_changed)
    
    _sprite_ppu_quick_handle.drag_performed.connect(_on_sprite_ppu_drag_performed)
    _sprite_offset_quick_handle.drag_performed.connect(_on_sprite_offset_drag_performed)
    
    _sprite_joint_quick_handle.drag_performed.connect(_on_joint_position_drag_performed)
    
    visibility_changed.connect(_update_part_content)
    visibility_changed.connect(_update_sprite_content)
    visibility_changed.connect(_update_joint_content)
    
    pass

#region Parts

func set_part_nodes(part_nodes: Array[Node]) -> void:
    
    for part_node in _part_nodes:
        
        if !DreamRiggerEditor.is_part_node_valid(part_node):
            continue
        
        part_node.disconnect(&"flip_state_changed",      _on_parts_flip_state_changed)
        part_node.disconnect(&"position_offset_changed", _on_parts_position_offset_changed)
        part_node.disconnect(&"rotation_z_changed",      _on_parts_rotation_z_changed)
        
        pass
    
    _part_nodes.clear()
    _part_nodes.append_array(part_nodes)
    
    for part_node in _part_nodes:
        
        part_node.connect(&"flip_state_changed",      _on_parts_flip_state_changed)
        part_node.connect(&"position_offset_changed", _on_parts_position_offset_changed)
        part_node.connect(&"rotation_z_changed",      _on_parts_rotation_z_changed)
        
        pass
    
    _update_part_content()
    
    pass

func _update_part_content() -> void:
    
    if !is_visible_in_tree():
        return
    
    _on_parts_flip_state_changed(false, false)
    _on_parts_position_offset_changed(Vector3.ZERO)
    _on_parts_rotation_z_changed(0)
    
    pass

#Parameter not used
func _on_parts_flip_state_changed(h: bool, v: bool) -> void:
    
    _part_flip_h_checkbox.set_pressed_no_signal(_part_flip_h)
    _part_flip_v_checkbox.set_pressed_no_signal(_part_flip_v)
    
    pass

#Parameter not used
func _on_parts_position_offset_changed(offset: Vector3) -> void:
    
    var offsets := _part_position_offset
    
    _part_position_offset_quick_handle.label_text = "Position Offset\nX : %0+6.3f\nY : %0+6.3f" % [
        offsets.x,
        offsets.y
    ]
    
    _part_z_layer_quick_handle.label_text = "Z Layer : %3d" % _part_z_layer
    
    pass

#Parameter not used
func _on_parts_rotation_z_changed(degree: float) -> void:
    
    _part_rotation_z_quick_handle.label_text = "Rotation Z\n%0+6.3f" % _part_rotation
    
    pass

func _on_part_position_offset_drag_performed(phase: DreamRiggerEditorQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    if _part_nodes.size() == 0:
        return
    
    match phase:
        
        DreamRiggerEditorQuickHandle.PHASE_BEGIN:
            
            for part_node in _part_nodes:
                part_node.set_meta(&"_position_offset", part_node.get_indexed(^"position_offset"))
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_MOVE:
            
            for part_node in _part_nodes:
                
                var parent_node    := part_node.get_parent()
                var resolved_delta := Vector3(mouse_delta.x, mouse_delta.y, 0)
                
                if part_node is Node2D:
                    resolved_delta /= 10.0
                
                elif part_node is Node3D:
                    resolved_delta.y *= -1
                
                if Input.is_key_pressed(KEY_CTRL):
                    resolved_delta = resolved_delta.floor()
                
                if parent_node is Node2D:
                    
                    var local_delta: Vector2 = parent_node.to_local(Vector2(resolved_delta.x, resolved_delta.y))
                    
                    resolved_delta.x = local_delta.x
                    resolved_delta.y = local_delta.y
                
                elif parent_node is Node3D:
                    
                    resolved_delta = parent_node.to_local(resolved_delta)
                    resolved_delta.z = 0
                    
                    pass
                
                if part_node.get_indexed(^"_parent_flip_h"): resolved_delta.x *= -1
                if part_node.get_indexed(^"_parent_flip_v"): resolved_delta.y *= -1
                
                var initial_value: Vector3 = part_node.get_meta(&"_position_offset")
                part_node.set_indexed(^"position_offset", initial_value + Vector3(resolved_delta.x, resolved_delta.y, 0))
                
                pass
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_SUBMIT:
            
            var context := DreamRiggerEditor.get_context()
            
            _undo_redo.create_action(
                "Set position offset of part(s)",
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            for part_node in _part_nodes:
                
                var old_value: Vector3 = part_node.get_meta(&"_position_offset")
                var new_value: Vector3 = part_node.get_indexed(^"position_offset")
                
                part_node.remove_meta(&"_position_offset")
                
                _undo_redo.add_do_property(part_node, &"position_offset", new_value)
                _undo_redo.add_undo_property(part_node, &"position_offset", old_value)
                
                if context.can_insert_animation_key:
                    
                    if old_value.x != new_value.x:
                        context.record_undo_redo_insert_animation_key(
                            _undo_redo,
                            part_node,
                            &"position_offset:x",
                            part_node.get_indexed(^"position_offset:x"),
                            Animation.TYPE_VALUE
                        )
                    
                    if old_value.y != new_value.y:
                        context.record_undo_redo_insert_animation_key(
                            _undo_redo,
                            part_node,
                            &"position_offset:y",
                            part_node.get_indexed(^"position_offset:y"),
                            Animation.TYPE_VALUE
                        )
                
                pass
            
            _undo_redo.commit_action()
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_CANCEL:
            
            for part_node in _part_nodes:
                
                var initial_value: Vector3 = part_node.get_meta(&"_position_offset")
                part_node.remove_meta(&"_position_offset")
                
                part_node.set_indexed(^"position_offset", initial_value)
                
                pass
            
            pass
    
    pass

func _on_part_rotation_z_drag_performed(phase: DreamRiggerEditorQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    _part_rotation_z_drag_delta = mouse_delta.limit_length(35 * 2.5)
    _part_rotation_z_quick_handle._dragging_mouse_position = _part_rotation_z_drag_delta
    
    _part_rotation_z_drag_delta /= 2.5
    
    if _part_nodes.size() == 0:
        return
    
    match phase:
        
        DreamRiggerEditorQuickHandle.PHASE_BEGIN:
            
            for part_node in _part_nodes:
                part_node.set_meta(&"_rotation_z", part_node.get_indexed(^"rotation_z"))
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_MOVE:
            
            for part_node in _part_nodes:
                
                var parent_node       := part_node.get_parent()
                var resolved_delta    := Vector3(_part_rotation_z_drag_delta.x, _part_rotation_z_drag_delta.y, 0)
                var resolved_rotation := 0.0
                
                #Resolve to local space
                if part_node is Node2D:
                    resolved_delta /= 10.0
                
                elif part_node is Node3D:
                    resolved_delta.y *= -1
                
                if parent_node is Node2D:
                    
                    var local_delta: Vector2 = parent_node.to_local(Vector2(resolved_delta.x, resolved_delta.y))
                    
                    resolved_delta.x = local_delta.x
                    resolved_delta.y = local_delta.y
                
                elif parent_node is Node3D:
                    
                    resolved_delta = parent_node.to_local(resolved_delta)
                    resolved_delta.z = 0
                    
                    pass
                
                #Resolve flipped space
                if part_node.get_indexed(^"is_root_part"):
                    
                    if part_node.get_indexed(^"flip_v"):
                        resolved_delta *= -1
                
                else:
                    
                    if part_node.get_indexed(^"_parent_flip_h"): resolved_delta.x *= -1
                    if part_node.get_indexed(^"_parent_flip_v"): resolved_delta.y *= -1
                    
                    if part_node.get_indexed(^"flip_v"):
                        resolved_delta *= -1
                    
                    pass
                
                #Resolve absolute rotation from world
                if part_node is Node2D:
                    
                    resolved_rotation = rad_to_deg(
                        atan2(
                            -resolved_delta.y,
                            resolved_delta.x
                        )
                    )
                
                elif part_node is Node3D:
                    
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
                
                part_node.set_indexed(^"rotation_z", resolved_rotation - 90.0)
                
                pass
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_SUBMIT:
            
            var context := DreamRiggerEditor.get_context()
            
            _undo_redo.create_action(
                "Set rotation_z of part(s)",
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            for part_node in _part_nodes:
                
                var old_value: float = part_node.get_meta(&"_rotation_z")
                var new_value: float = part_node.get_indexed(^"rotation_z")
                
                part_node.remove_meta(&"_rotation_z")
                
                _undo_redo.add_do_property(part_node, &"rotation_z", new_value)
                _undo_redo.add_undo_property(part_node, &"rotation_z", old_value)
                
                if context.can_insert_animation_key:
                    context.record_undo_redo_insert_animation_key(
                        _undo_redo,
                        part_node,
                        &"rotation_z",
                        new_value,
                        Animation.TYPE_VALUE
                    )
                
                pass
            
            _undo_redo.commit_action()
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_CANCEL:
            
            for part_node in _part_nodes:
                
                var initial_value: float = part_node.get_meta(&"_rotation_z")
                part_node.remove_meta(&"_rotation_z")
                
                part_node.set_indexed(^"rotation_z", initial_value)
                
                pass
            
            pass
    
    _part_rotation_z_quick_handle.queue_redraw()
    
    pass

func _on_part_rotation_z_quick_handle_draw() -> void:
    
    var context := _part_rotation_z_quick_handle
    
    var center := context.size / 2
    
    context.draw_circle(center, 35, Color.DIM_GRAY)
    
    if !_part_rotation_z_quick_handle.is_dragging:
        return
    
    context.draw_circle(center, 5, Color.GRAY)
    
    var delta = _part_rotation_z_drag_delta.clamp(-center, center)
    
    context.draw_line(center, center + delta, Color.GRAY, 5)
    context.draw_circle(center + delta, 10, Color.GRAY)
    
    pass

func _on_part_flip_h_toggled(value: bool) -> void:
    
    if _part_nodes.size() == 0:
        return
    
    var context := DreamRiggerEditor.get_context()
    
    _undo_redo.create_action(
        "Set flip H of part(s)",
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    for part_node in _part_nodes:
        
        _undo_redo.add_do_property(part_node, &"flip_h", value)
        _undo_redo.add_undo_property(part_node, &"flip_h", part_node.get_indexed(^"flip_h"))
        
        if context.can_insert_animation_key:
            context.record_undo_redo_insert_animation_key(
                _undo_redo,
                part_node,
                &"flip_h",
                value,
                Animation.TYPE_VALUE
            )
        
        pass
    
    _undo_redo.commit_action()
    
    pass

func _on_part_flip_v_toggled(value: bool) -> void:
    
    if _part_nodes.size() == 0:
        return
    
    var context := DreamRiggerEditor.get_context()
    
    _undo_redo.create_action(
        "Set flip V of part(s)",
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    for part_node in _part_nodes:
        
        _undo_redo.add_do_property(part_node, &"flip_v", value)
        _undo_redo.add_undo_property(part_node, &"flip_v", part_node.get_indexed(^"flip_v"))
        
        if context.can_insert_animation_key:
            context.record_undo_redo_insert_animation_key(
                _undo_redo,
                part_node,
                &"flip_v",
                value,
                Animation.TYPE_VALUE
            )
        
        pass
    
    _undo_redo.commit_action()
    
    pass

func _on_part_z_layer_drag_performed(phase: DreamRiggerEditorQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    if _part_nodes.size() == 0:
        return
    
    match phase:
        
        DreamRiggerEditorQuickHandle.PHASE_BEGIN:
            
            for part_node in _part_nodes:
                part_node.set_meta(&"_position_offset", part_node.get_indexed(^"position_offset"))
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_MOVE:
            
            for part_node in _part_nodes:
                
                var initial_value: Vector3 = part_node.get_meta(&"_position_offset")
                part_node.set_indexed(^"position_offset", initial_value + Vector3(0, 0, -floor(mouse_delta.y / 50)))
                
                pass
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_SUBMIT:
            
            var context := DreamRiggerEditor.get_context()
            
            _undo_redo.create_action(
                "Set Z layer of part(s)",
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            for part_node in _part_nodes:
                
                var old_value: Vector3 = part_node.get_meta(&"_position_offset")
                var new_value: Vector3 = part_node.get_indexed(^"position_offset")
                
                part_node.remove_meta(&"_position_offset")
                
                _undo_redo.add_do_property(part_node, &"position_offset", new_value)
                _undo_redo.add_undo_property(part_node, &"position_offset", old_value)
                
                if context.can_insert_animation_key:
                    context.record_undo_redo_insert_animation_key(
                        _undo_redo,
                        part_node,
                        &"position_offset:z",
                        new_value.z,
                        Animation.TYPE_VALUE
                    )
                
                pass
            
            _undo_redo.commit_action()
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_CANCEL:
            
            for part_node in _part_nodes:
                
                var initial_value: Vector3 = part_node.get_meta(&"_position_offset")
                part_node.remove_meta(&"_position_offset")
                
                part_node.set_indexed(^"position_offset", initial_value)
                
                pass
            
            pass
    
    pass

#endregion

#region Sprites

func set_sprites(sprites: Array[DreamRiggerSprite]) -> void:
    
    for sprite in _sprites:
        
        if !is_instance_valid(sprite):
            continue
        
        sprite.changed.disconnect(_update_sprite_content)
        
        pass
    
    _sprites.clear()
    _sprites.append_array(sprites)
    
    for sprite in _sprites:
        
        sprite.changed.connect(_update_sprite_content)
        
        pass
    
    _update_sprite_content()
    
    _sprite_joint_list.set_sprites(_sprites)
    
    pass

func _update_sprite_content() -> void:
    
    if !is_visible_in_tree():
        return
    
    var offsets := _sprite_offset
    var ppus    := _sprite_pixels_per_unit
    
    _sprite_offset_quick_handle.label_text = "Offset\nX : %0+6.3f\nY : %0+6.3f" % [
        offsets.x,
        offsets.y
    ]
    
    _sprite_ppu_quick_handle.label_text = "PPU\n%06.3f" % ppus
    
    pass

func _on_sprite_ppu_drag_performed(phase: DreamRiggerEditorQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    if _sprites.size() == 0:
        return
    
    match phase:
        
        DreamRiggerEditorQuickHandle.PHASE_BEGIN:
            
            for sprite in _sprites:
                sprite.set_meta(&"_pixels_per_unit", sprite.pixels_per_unit)
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_MOVE:
            
            for sprite in _sprites:
                
                if Input.is_key_pressed(KEY_CTRL):
                    mouse_delta = mouse_delta.floor()
                
                var initial_value: float = sprite.get_meta(&"_pixels_per_unit")
                sprite.pixels_per_unit = max(initial_value + mouse_delta.x, 0.001)
                
                pass
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_SUBMIT:
            
            _undo_redo.create_action(
                "Set pixels per unit of sprite(s).",
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            for sprite in _sprites:
                
                var initial_value: float = sprite.get_meta(&"_pixels_per_unit")
                sprite.remove_meta(&"_pixels_per_unit")
                
                _undo_redo.add_do_property(sprite, &"pixels_per_unit", sprite.pixels_per_unit)
                _undo_redo.add_undo_property(sprite, &"pixels_per_unit", initial_value)
                
                pass
            
            _undo_redo.commit_action()
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_CANCEL:
            
            for sprite in _sprites:
                
                var initial_value: float = sprite.get_meta(&"_pixels_per_unit")
                sprite.remove_meta(&"_pixels_per_unit")
                
                sprite.pixels_per_unit = initial_value
                
                pass
            
            pass
    
    pass

func _on_sprite_offset_drag_performed(phase: DreamRiggerEditorQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    if _sprites.size() == 0:
        return
    
    match phase:
        
        DreamRiggerEditorQuickHandle.PHASE_BEGIN:
            
            for sprite in _sprites:
                sprite.set_meta(&"_offset", sprite.offset)
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_MOVE:
            
            for sprite in _sprites:
                
                var resolved_delta := Vector3(mouse_delta.x, mouse_delta.y, 0)
                
                var context_node := _get_relevant_part_node_of_sprite(sprite)
                
                if is_instance_valid(context_node):
                    
                    if context_node.get_indexed(^"resolved_flip_h"): resolved_delta.x *= -1
                    if context_node.get_indexed(^"resolved_flip_v"): resolved_delta.y *= -1
                    
                    pass
                
                if context_node is Node2D:
                    
                    resolved_delta /= 10.0
                    
                    if Input.is_key_pressed(KEY_CTRL):
                        resolved_delta = resolved_delta.floor()
                    
                    var local_delta: Vector2 = context_node.to_local(Vector2(resolved_delta.x, resolved_delta.y))
                    
                    resolved_delta.x = local_delta.x
                    resolved_delta.y = local_delta.y
                
                elif context_node is Node3D:
                    
                    resolved_delta.y *= -1
                    
                    if Input.is_key_pressed(KEY_CTRL):
                        resolved_delta = resolved_delta.floor()
                    
                    resolved_delta = context_node.to_local(resolved_delta)
                    
                    pass
                
                var initial_value: Vector3 = sprite.get_meta(&"_offset")
                sprite.offset = initial_value + Vector3(resolved_delta.x, resolved_delta.y, 0)
                
                pass
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_SUBMIT:
            
            _undo_redo.create_action(
                "Set offset of sprite(s).",
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            for sprite in _sprites:
                
                var initial_value: Vector3 = sprite.get_meta(&"_offset")
                sprite.remove_meta(&"_offset")
                
                _undo_redo.add_do_property(sprite, &"offset", sprite.offset)
                _undo_redo.add_undo_property(sprite, &"offset", initial_value)
                
                pass
            
            _undo_redo.commit_action()
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_CANCEL:
            
            for sprite in _sprites:
                
                var initial_value: Vector3 = sprite.get_meta(&"_offset")
                sprite.remove_meta(&"_offset")
                
                sprite.offset = initial_value
                
                pass
            
            pass
    
    pass

func _get_relevant_part_node_of_sprite(sprite: DreamRiggerSprite) -> Node:
    
    #First: Find displaying owners
    for part_node in _part_nodes:
        if part_node.get_indexed(^"sprite") == sprite:
            return part_node
    
    #Second: Find data oriented owners
    var context := DreamRiggerEditor.get_context()
    
    var owner_pose := context.sprite_owners[sprite]
    
    if !is_instance_valid(owner_pose):
        return null
    
    var owner_node := context.pose_owners[owner_pose]
    
    return owner_node

#endregion

#region Joints

func _on_joint_list_selection_changed(joints: Array[DreamRiggerJoint]) -> void:
    
    for joint in _joints:
        
        if !is_instance_valid(joint):
            continue
        
        joint.changed_ext.disconnect(_on_joint_changed)
        
        pass
    
    _joints.clear()
    _joints.append_array(joints)
    
    for joint in _joints:
        
        if !is_instance_valid(joint):
            continue
        
        joint.changed_ext.connect(_on_joint_changed)
        
        pass
    
    _update_joint_content()
    
    pass

func _on_joint_changed(sender: DreamRiggerJoint) -> void:
    
    _update_joint_content()
    
    pass

func _update_joint_content() -> void:
    
    if !is_visible_in_tree():
        return
    
    _sprite_joint_quick_handle.label_text = "%s Joint(s)" % _joints.size()
    
    pass


#TODO: Handle joint values with quick handle

func _on_joint_position_drag_performed(phase: DreamRiggerEditorQuickHandle.Phase, mouse_delta: Vector2) -> void:
    
    if _joints.size() == 0:
        return
    
    match phase:
        
        DreamRiggerEditorQuickHandle.PHASE_BEGIN:
            
            for joint in _joints:
                joint.set_meta(&"_position", joint.position)
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_MOVE:
            
            for joint in _joints:
                
                var resolved_delta := Vector3(mouse_delta.x, mouse_delta.y, 0)
                
                var context_node := _get_relevant_part_node_of_joint(joint)
                
                if is_instance_valid(context_node):
                    
                    print(context_node.name)
                    
                    if context_node.get_indexed(^"resolved_flip_h"): resolved_delta.x *= -1
                    if context_node.get_indexed(^"resolved_flip_v"): resolved_delta.y *= -1
                    
                    pass
                
                if context_node is Node2D:
                    
                    resolved_delta /= 10.0
                    
                    if Input.is_key_pressed(KEY_CTRL):
                        resolved_delta = resolved_delta.floor()
                    
                    var local_delta: Vector2 = context_node.to_local(Vector2(resolved_delta.x, resolved_delta.y))
                    
                    resolved_delta.x = local_delta.x
                    resolved_delta.y = local_delta.y
                
                elif context_node is Node3D:
                    
                    resolved_delta.y *= -1
                    
                    if Input.is_key_pressed(KEY_CTRL):
                        resolved_delta = resolved_delta.floor()
                    
                    resolved_delta = context_node.to_local(resolved_delta)
                    
                    pass
                
                var initial_value: Vector3 = joint.get_meta(&"_position")
                joint.position = initial_value + Vector3(resolved_delta.x, resolved_delta.y, 0)
                
                pass
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_SUBMIT:
            
            _undo_redo.create_action(
                "Set position of joint(s).",
                UndoRedo.MERGE_DISABLE,
                EditorInterface.get_edited_scene_root()
            )
            
            for joint in _joints:
                
                var initial_value: Vector3 = joint.get_meta(&"_position")
                joint.remove_meta(&"_position")
                
                _undo_redo.add_do_property(joint, &"position", joint.position)
                _undo_redo.add_undo_property(joint, &"position", initial_value)
                
                pass
            
            _undo_redo.commit_action()
            
            pass
        
        DreamRiggerEditorQuickHandle.PHASE_CANCEL:
            
            for joint in _joints:
                
                var initial_value: Vector3 = joint.get_meta(&"_position")
                joint.remove_meta(&"_position")
                
                joint.position = initial_value
                
                pass
            
            pass
    
    pass

func _get_relevant_part_node_of_joint(joint: DreamRiggerJoint) -> Node:
    
    #First: Find displaying owners
    for part_node in _part_nodes:
        
        var sprite: DreamRiggerSprite = part_node.get_indexed(^"sprite")
        
        if !is_instance_valid(sprite):
            continue
        
        return _get_relevant_part_node_of_sprite(sprite)
    
    #Second: Find data oriented owners
    var context := DreamRiggerEditor.get_context()
    
    var owner_sprite := context.joint_owners[joint]
    
    if !is_instance_valid(owner_sprite):
        return null
    
    return _get_relevant_part_node_of_sprite(owner_sprite)

#endregion
