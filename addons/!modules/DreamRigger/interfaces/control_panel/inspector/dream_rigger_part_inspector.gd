@tool
class_name DreamRiggerPartInspector extends Control

signal recordable_property_changed(part: Node, property: StringName, value: Variant)

var _undo_redo := EditorInterface.get_editor_undo_redo()

var _position_offset_container: FlowContainer
var _z_layer_container: FlowContainer
var _rotation_z_container: FlowContainer

var _position_offset_editor_property: EditorProperty
var _z_layer_editor_property: EditorProperty
var _rotation_z_editor_property: EditorProperty

var _flip_h_checkbox: CheckBox
var _flip_v_checkbox: CheckBox

var _binding_part: Node

var _binding_part_position_offset: Vector2:
    get:
        if !is_instance_valid(_binding_part):
            return Vector2.ZERO
        
        return Vector2(
            _binding_part.position_offset.x,
            _binding_part.position_offset.y
        )

var _binding_part_z_layer: int:
    get:
        if !is_instance_valid(_binding_part):
            return 0
        
        return floori(_binding_part.position_offset.z)

var _binding_part_rotation: float:
    get:
        if !is_instance_valid(_binding_part):
            return 0
        
        return _binding_part.rotation_z

func _ready() -> void:
    
    _position_offset_container = %"OffsetContainer"
    _z_layer_container         = %"ZLayerContainer"
    _rotation_z_container      = %"RotationZContainer"
    
    _position_offset_editor_property = EditorInspector.instantiate_property_editor(
        self,
        TYPE_VECTOR2,
        &"_binding_part_position_offset",
        PROPERTY_HINT_NONE,
        "",
        PROPERTY_USAGE_EDITOR,
        true
    )
    _position_offset_editor_property.draw_label = false
    _position_offset_editor_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    _z_layer_editor_property = EditorInspector.instantiate_property_editor(
        self,
        TYPE_INT,
        &"_binding_part_z_layer",
        PROPERTY_HINT_NONE,
        "",
        PROPERTY_USAGE_EDITOR,
        true
    )
    _z_layer_editor_property.draw_label = false
    _z_layer_editor_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    _rotation_z_editor_property = EditorInspector.instantiate_property_editor(
        self,
        TYPE_FLOAT,
        &"_binding_part_rotation",
        PROPERTY_HINT_NONE,
        "",
        PROPERTY_USAGE_EDITOR,
        true
    )
    _rotation_z_editor_property.draw_label = false
    _rotation_z_editor_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var z_layer_spin_slider := _z_layer_editor_property.get_child(0, true) as EditorSpinSlider
    z_layer_spin_slider.step = 0.2
    
    _position_offset_container.add_child(_position_offset_editor_property)
    _z_layer_container.add_child(_z_layer_editor_property)
    _rotation_z_container.add_child(_rotation_z_editor_property)
    
    _position_offset_editor_property.set_object_and_property(self, &"_binding_part_position_offset")
    _z_layer_editor_property.set_object_and_property(self, &"_binding_part_z_layer")
    _rotation_z_editor_property.set_object_and_property(self, &"_binding_part_rotation")
    
    _position_offset_editor_property.property_changed.connect(_on_position_offset_property_changed)
    _z_layer_editor_property.property_changed.connect(_on_z_layer_property_changed)
    _rotation_z_editor_property.property_changed.connect(_on_rotation_property_changed)
    
    _flip_h_checkbox = %"FlipHCheckBox"
    _flip_v_checkbox = %"FlipVCheckBox"
    
    _flip_h_checkbox.toggled.connect(_on_flip_h_toggled)
    _flip_v_checkbox.toggled.connect(_on_flip_v_toggled)
    
    _position_offset_editor_property.read_only = false
    _z_layer_editor_property.read_only         = false
    _rotation_z_editor_property.read_only      = false
    
    _flip_h_checkbox.disabled = false
    _flip_v_checkbox.disabled = false
    
    pass

func _enter_tree() -> void:
    
    pass

func bind_part(part: Node) -> void:
    
    unbind_part()
    
    if part is not DreamRiggerPart2D && part is not DreamRiggerPart3D:
        return
    
    _binding_part = part
    
    if !is_instance_valid(_binding_part):
        return
    
    _position_offset_editor_property.read_only = false
    _z_layer_editor_property.read_only         = false
    _rotation_z_editor_property.read_only      = false
    
    _flip_h_checkbox.disabled = false
    _flip_v_checkbox.disabled = false
    
    if !_binding_part.position_offset_changed.is_connected(_on_binding_part_offset_changed):
        _binding_part.position_offset_changed.connect(_on_binding_part_offset_changed)
    
    if !_binding_part.rotation_z_changed.is_connected(_on_binding_part_rotation_z_changed):
        _binding_part.rotation_z_changed.connect(_on_binding_part_rotation_z_changed)
    
    if !_binding_part.flip_state_changed.is_connected(_on_binding_part_flip_state_changed):
        _binding_part.flip_state_changed.connect(_on_binding_part_flip_state_changed)
    
    _on_binding_part_offset_changed(_binding_part.position_offset)
    _on_binding_part_rotation_z_changed(_binding_part.rotation_z)
    _on_binding_part_flip_state_changed(_binding_part.flip_h, _binding_part.flip_v)
    
    pass

func unbind_part() -> void:
    
    _position_offset_editor_property.read_only = true
    _z_layer_editor_property.read_only         = true
    _rotation_z_editor_property.read_only        = true
    
    _flip_h_checkbox.disabled = true
    _flip_v_checkbox.disabled = true
    
    if !is_instance_valid(_binding_part):
        return
    
    if _binding_part.position_offset_changed.is_connected(_on_binding_part_offset_changed):
        _binding_part.position_offset_changed.disconnect(_on_binding_part_offset_changed)
    
    if _binding_part.rotation_z_changed.is_connected(_on_binding_part_rotation_z_changed):
        _binding_part.rotation_z_changed.disconnect(_on_binding_part_rotation_z_changed)
    
    if _binding_part.flip_state_changed.is_connected(_on_binding_part_flip_state_changed):
        _binding_part.flip_state_changed.disconnect(_on_binding_part_flip_state_changed)
    
    _on_binding_part_offset_changed(Vector3.ZERO)
    _on_binding_part_flip_state_changed(false, false)
    
    _binding_part = null
    
    pass

func _on_binding_part_offset_changed(offset: Vector3) -> void:
    
    _position_offset_editor_property.update_property()
    _z_layer_editor_property.update_property()
    
    pass

func _on_binding_part_rotation_z_changed(degree: float) -> void:
    
    _rotation_z_editor_property.update_property()
    
    pass

func _on_binding_part_flip_state_changed(h: bool, v: bool) -> void:
    
    _flip_h_checkbox.set_pressed_no_signal(h)
    _flip_v_checkbox.set_pressed_no_signal(v)
    
    pass

func _on_position_offset_property_changed(
    property: StringName,
    value:    Variant,
    field:    StringName,
    changing: bool) -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    var position_offset := Vector3(value.x, value.y, _binding_part.position_offset.z)
    
    _set_undo_redo_value(
        "Change position offset of part '%s'" % _binding_part.name,
        _binding_part,
        &"position_offset",
        _binding_part.position_offset,
        position_offset,
        UndoRedo.MERGE_ENDS,
        true
    )
    
    pass

func _on_z_layer_property_changed(
    property: StringName,
    value:    Variant,
    field:    StringName,
    changing: bool) -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    var position_offset: Vector3 = _binding_part.position_offset
    position_offset.z = floor(value)
    
    _set_undo_redo_value(
        "Change Z layer (position offset Z) of '%s'" % _binding_part.name,
        _binding_part,
        &"position_offset",
        _binding_part.position_offset,
        position_offset,
        UndoRedo.MERGE_ENDS,
        true
    )
    
    pass

func _on_rotation_property_changed(
    property: StringName,
    value:    Variant,
    field:    StringName,
    changing: bool) -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    _set_undo_redo_value(
        "Change rotation_z of '%s'" % _binding_part.name,
        _binding_part,
        &"rotation_z",
        _binding_part.rotation_z,
        value,
        UndoRedo.MERGE_ENDS,
        true
    )
    
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

#FIXME: Boilerplate code, duplicated in DreamRiggerScratchPadInspector.
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