@tool
class_name DreamRiggerEditorPartInspector extends Control

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
        
        _position_offset_editor_property.read_only = !value
        _z_layer_editor_property.read_only         = !value
        _rotation_editor_property.read_only        = !value
        
        enabled = value
        
        pass

var _undo_redo := EditorInterface.get_editor_undo_redo()

@onready var _position_offset_container: HFlowContainer = %OffsetContainer
@onready var _z_layer_container:         HFlowContainer = %ZLayerContainer
@onready var _rotation_container:        HFlowContainer = %RotationContainer

@onready var _flip_h_checkbox: CheckBox = %FlipHCheckBox
@onready var _flip_v_checkbox: CheckBox = %FlipVCheckBox

var _part_nodes: Array[Node]

var _position_offset_editor_property: EditorProperty
var _z_layer_editor_property:         EditorProperty
var _rotation_editor_property:        EditorProperty

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

#region Signal methods

func _ready() -> void:
    
    var context := DreamRiggerEditor.get_context()
    
    context.parts_changed.connect(set_part_nodes)
    
    _position_offset_editor_property = EditorInspector.instantiate_property_editor(
        self,
        TYPE_VECTOR2,
        &"_part_position_offset",
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
        &"_part_z_layer",
        PROPERTY_HINT_NONE,
        "",
        PROPERTY_USAGE_EDITOR,
        true
    )
    _z_layer_editor_property.draw_label = false
    _z_layer_editor_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    _rotation_editor_property = EditorInspector.instantiate_property_editor(
        self,
        TYPE_FLOAT,
        &"_part_rotation",
        PROPERTY_HINT_NONE,
        "",
        PROPERTY_USAGE_EDITOR,
        true
    )
    _rotation_editor_property.draw_label = false
    _rotation_editor_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    var z_layer_spin_slider := _z_layer_editor_property.get_child(0, true) as EditorSpinSlider
    z_layer_spin_slider.step = 0.2
    
    _position_offset_container.add_child(_position_offset_editor_property)
    _z_layer_container.add_child(_z_layer_editor_property)
    _rotation_container.add_child(_rotation_editor_property)
    
    _position_offset_editor_property.set_object_and_property(self, &"_part_position_offset")
    _z_layer_editor_property.set_object_and_property(self, &"_part_z_layer")
    _rotation_editor_property.set_object_and_property(self, &"_part_rotation")
    
    _position_offset_editor_property.property_changed.connect(_on_position_offset_property_changed)
    _z_layer_editor_property.property_changed.connect(_on_z_layer_property_changed)
    _rotation_editor_property.property_changed.connect(_on_rotation_property_changed)
    
    _flip_h_checkbox.toggled.connect(_on_flip_h_toggled)
    _flip_v_checkbox.toggled.connect(_on_flip_v_toggled)
    
    _position_offset_editor_property.read_only = false
    _z_layer_editor_property.read_only         = false
    _rotation_editor_property.read_only        = false
    
    _flip_h_checkbox.disabled = false
    _flip_v_checkbox.disabled = false
    
    visibility_changed.connect(_update_content)
    
    pass


#Parameter not used
func _on_parts_flip_state_changed(h: bool, v: bool) -> void:
    
    _flip_h_checkbox.set_pressed_no_signal(_part_flip_h)
    _flip_v_checkbox.set_pressed_no_signal(_part_flip_v)
    
    pass

#Parameter not used
func _on_parts_position_offset_changed(offset: Vector3) -> void:
    
    _position_offset_editor_property.update_property()
    _z_layer_editor_property.update_property()
    pass

#Parameter not used
func _on_parts_rotation_z_changed(degree: float) -> void:
    
    _rotation_editor_property.update_property()
    pass

func _on_position_offset_property_changed(
    property: StringName,
    value:    Variant,
    field:    StringName,
    changing: bool) -> void:
    
    if _part_nodes.size() == 0:
        return
    
    var context := DreamRiggerEditor.get_context()
    
    _undo_redo.create_action(
        "Set position offset %s of part(s)" % field,
        UndoRedo.MERGE_ENDS,
        EditorInterface.get_edited_scene_root()
    )
    
    for part_node in _part_nodes:
        
        var old_value: Vector3 = part_node.get_indexed(^"position_offset")
        var new_value: Vector3 = old_value
        
        match field:
            "x": new_value.x = value.x
            "y": new_value.y = value.y
        
        _undo_redo.add_do_property(part_node, &"position_offset", new_value)
        _undo_redo.add_undo_property(part_node, &"position_offset", old_value)
        
        if context.can_insert_animation_key:
            
            var property_name:   StringName
            var track_key_value: float
            
            match field:
                
                "x":
                    
                    property_name   = &"position_offset:x"
                    track_key_value = new_value.x
                    
                    pass
                
                "y":
                    
                    property_name   = &"position_offset:y"
                    track_key_value = new_value.y
                    
                    pass
            
            context.record_undo_redo_insert_animation_key(
                _undo_redo,
                part_node,
                property_name,
                track_key_value,
                Animation.TYPE_VALUE
            )
            
            pass
        
        pass
    
    _undo_redo.commit_action()
    
    pass

func _on_z_layer_property_changed(
    property: StringName,
    value:    Variant,
    field:    StringName,
    changing: bool) -> void:
    
    if _part_nodes.size() == 0:
        return
    
    var context := DreamRiggerEditor.get_context()
    
    _undo_redo.create_action(
        "Set z layer of part(s)",
        UndoRedo.MERGE_ENDS,
        EditorInterface.get_edited_scene_root()
    )
    
    for part_node in _part_nodes:
        
        var old_value: Vector3 = part_node.get_indexed(^"position_offset")
        var new_value: Vector3 = old_value
        
        new_value.z = value
        
        _undo_redo.add_do_property(part_node, &"position_offset", new_value)
        _undo_redo.add_undo_property(part_node, &"position_offset", old_value)
        
        if context.can_insert_animation_key:
            context.record_undo_redo_insert_animation_key(
                _undo_redo,
                part_node,
                &"position_offset:z",
                value,
                Animation.TYPE_VALUE
            )
        
        pass
    
    _undo_redo.commit_action()
    
    pass

func _on_rotation_property_changed(
    property: StringName,
    value:    Variant,
    field:    StringName,
    changing: bool) -> void:
    
    if _part_nodes.size() == 0:
        return
    
    var context := DreamRiggerEditor.get_context()
    
    _undo_redo.create_action(
        "Set rotation of part(s)",
        UndoRedo.MERGE_ENDS,
        EditorInterface.get_edited_scene_root()
    )
    
    for part_node in _part_nodes:
        
        _undo_redo.add_do_property(part_node, &"rotation_z", value)
        _undo_redo.add_undo_property(part_node, &"rotation_z", part_node.get_indexed(^"rotation_z"))
        
        if context.can_insert_animation_key:
            context.record_undo_redo_insert_animation_key(
                _undo_redo,
                part_node,
                &"rotation_z",
                value,
                Animation.TYPE_VALUE
            )
        
        pass
    
    _undo_redo.commit_action()
    
    pass

func _on_flip_h_toggled(value: bool) -> void:
    
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

func _on_flip_v_toggled(value: bool) -> void:
    
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

#endregion

#region API methods

## Set context of [DreamRiggerPart2D]s or [DreamRiggerPart3D]s.
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
    
    _update_content()
    
    pass

#endregion

#region Operation methods

func _update_content() -> void:
    
    if !is_visible_in_tree():
        return
    
    _on_parts_flip_state_changed(false, false)
    _on_parts_position_offset_changed(Vector3.ZERO)
    _on_parts_rotation_z_changed(0)
    
    pass

#endregion
