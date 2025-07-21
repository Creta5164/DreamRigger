@tool
class_name DreamRiggerSpriteInspector extends Control

var _undo_redo := EditorInterface.get_editor_undo_redo()

var _name_line_edit: LineEdit

var _offset_container: FlowContainer
var _ppu_container: FlowContainer

var _offset_editor_property: EditorProperty
var _ppu_editor_property: EditorProperty

var _joint_list: DreamRiggerInspectorSpriteJointList

var _joint_position_container: FlowContainer

var _joint_position_editor_property: EditorProperty

var _context_part: Node
var _binding_sprites: Array[DreamRiggerSprite]
var _selected_joints: Array[StringName]

var _binding_sprites_offset: Vector2:
    get:
        if _binding_sprites.size() != 1:
            return Vector2.ZERO
        
        return Vector2(
            _binding_sprites[0].offset.x,
            _binding_sprites[0].offset.y
        )

var _binding_sprites_pixels_per_unit: float:
    get:
        if _binding_sprites.size() != 1:
            return 0
        
        return _binding_sprites[0].pixels_per_unit

var _binding_sprites_joint_position: Vector2:
    get:
        if _binding_sprites.size() != 1:
            return Vector2.ZERO
        
        if _selected_joints.size() != 1:
            return Vector2.ZERO
        
        var sprite := _binding_sprites[0]
        var joint := sprite.get_joint(_selected_joints[0])
        
        if !is_instance_valid(joint):
            return Vector2.ZERO
        
        return Vector2(
            joint.position.x,
            joint.position.y
        )

func _ready() -> void:
    
    _name_line_edit = %"SpriteNameLineEdit"
    _joint_list     = %"InspectorJointList"
    
    _offset_container = %"SpritePivotContainer"
    _ppu_container   = %"SpritePPUContainer"
    
    _joint_position_container = %"JointPositionContainer"
    
    _offset_editor_property = EditorInspector.instantiate_property_editor(
        self,
        TYPE_VECTOR2,
        &"_binding_sprites_offset",
        PROPERTY_HINT_NONE,
        "",
        PROPERTY_USAGE_EDITOR,
        true
    )
    _offset_editor_property.read_only = true
    _offset_editor_property.draw_label = false
    _offset_editor_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    _ppu_editor_property = EditorInspector.instantiate_property_editor(
        self,
        TYPE_FLOAT,
        &"_binding_sprites_pixels_per_unit",
        PROPERTY_HINT_NONE,
        "",
        PROPERTY_USAGE_EDITOR,
        true
    )
    _ppu_editor_property.read_only = true
    _ppu_editor_property.draw_label = false
    _ppu_editor_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    _joint_position_editor_property = EditorInspector.instantiate_property_editor(
        self,
        TYPE_VECTOR2,
        &"_binding_sprites_joint_position",
        PROPERTY_HINT_NONE,
        "",
        PROPERTY_USAGE_EDITOR,
        true
    )
    _joint_position_editor_property.read_only = true
    _joint_position_editor_property.draw_label = false
    _joint_position_editor_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    _offset_editor_property.set_object_and_property(self, &"_binding_sprites_offset")
    _ppu_editor_property.set_object_and_property(self, &"_binding_sprites_pixels_per_unit")
    _joint_position_editor_property.set_object_and_property(self, &"_binding_sprites_joint_position")
    
    _offset_container.add_child(_offset_editor_property)
    _ppu_container.add_child(_ppu_editor_property)
    _joint_position_container.add_child(_joint_position_editor_property)
    
    _name_line_edit.text_submitted.connect(_on_name_submitted)
    
    _offset_editor_property.property_changed.connect(_on_offset_property_changed)
    _ppu_editor_property.property_changed.connect(_on_ppu_property_changed)
    _joint_position_editor_property.property_changed.connect(_on_joint_position_property_changed)
    
    _joint_list.selection_changed.connect(_on_joint_selection_changed)
    
    pass

func set_part_context(part: Node) -> void:
    
    if part is not DreamRiggerPart2D && part is not DreamRiggerPart3D:
        return
    
    _joint_list.set_part_context(part)
    
    pass

func bind_sprites(sprites: Array[DreamRiggerSprite]) -> void:
    
    unbind_sprites()
    
    if sprites.size() == 0:
        return
    
    _offset_editor_property.read_only = false
    _ppu_editor_property.read_only = false
    _joint_position_editor_property.read_only = false
    
    for sprite: DreamRiggerSprite in sprites:
        
        if !is_instance_valid(sprite):
            continue
        
        sprite.changed.connect(_on_sprite_modified.bind(sprite))
        _binding_sprites.append(sprite)
        
        pass
    
    _update_name()
    _offset_editor_property.update_property()
    _ppu_editor_property.update_property()
    _joint_position_editor_property.update_property()
    _joint_list.bind_sprites(sprites)
    
    pass

func unbind_sprites() -> void:
    
    if _binding_sprites.size() == 0:
        return
    
    for sprite: DreamRiggerSprite in _binding_sprites:
        
        sprite.changed.disconnect(_on_sprite_modified.bind(sprite))
        pass
    
    _binding_sprites.clear()
    
    _offset_editor_property.read_only = true
    _ppu_editor_property.read_only = true
    _joint_position_editor_property.read_only = true
    
    _update_name()
    _offset_editor_property.update_property()
    _ppu_editor_property.update_property()
    _joint_position_editor_property.update_property()
    _joint_list.unbind_sprites()
    
    pass

func _on_sprite_modified(sprite: DreamRiggerSprite) -> void:
    
    _update_name()
    _offset_editor_property.update_property()
    _ppu_editor_property.update_property()
    _joint_position_editor_property.update_property()
    _joint_list.update_content()
    
    pass

func _update_name() -> void:
    
    if _binding_sprites.size() == 0:
        
        _name_line_edit.text = ''
        return
    
    var is_mixed := false
    var name     := &""
    
    for sprite: DreamRiggerSprite in _binding_sprites:
        
        if !is_instance_valid(sprite):
            continue
        
        if name == &"":
            
            name = sprite.name
            continue
        
        if name != sprite.name:
            
            is_mixed = true
            break
        
        pass
    
    if is_mixed:
        
        _name_line_edit.text = "-"
        return
    
    _name_line_edit.text = name
    
    pass

func _on_name_submitted(value: String) -> void:
    
    if _binding_sprites.size() == 0:
        return
    
    _undo_redo.create_action(
        "Change name of %s sprite(s) to '%s'" % [
            _binding_sprites.size(),
            value
        ],
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    for sprite: DreamRiggerSprite in _binding_sprites:
        
        if !is_instance_valid(sprite):
            continue
        
        _undo_redo.add_do_property(sprite, &"name", value)
        _undo_redo.add_undo_property(sprite, &"name", sprite.name)
    
    _undo_redo.commit_action()
    
    pass

func _on_offset_property_changed(
    property: StringName,
    value:    Variant,
    field:    StringName,
    changing: bool) -> void:
    
    if _binding_sprites.size() == 0:
        return
    
    var offset := Vector3(
        value.x,
        value.y,
        0
    )
    
    _undo_redo.create_action(
        "Change offset of %s sprite(s)" % _binding_sprites.size(),
        UndoRedo.MERGE_ENDS,
        EditorInterface.get_edited_scene_root()
    )
    
    for sprite: DreamRiggerSprite in _binding_sprites:
        
        if !is_instance_valid(sprite):
            continue
        
        _undo_redo.add_do_property(sprite, &"offset", offset)
        _undo_redo.add_undo_property(sprite, &"offset", sprite.offset)
        
        pass
    
    _undo_redo.commit_action()
    
    pass

func _on_ppu_property_changed(
    property: StringName,
    value:    Variant,
    field:    StringName,
    changing: bool) -> void:
    
    if _binding_sprites.size() == 0:
        return
    
    value = max(value, 0.001)
    
    _undo_redo.create_action(
        "Change pixels per unit of %s sprite(s)" % _binding_sprites.size(),
        UndoRedo.MERGE_ENDS,
        EditorInterface.get_edited_scene_root()
    )
    
    for sprite: DreamRiggerSprite in _binding_sprites:
        
        if !is_instance_valid(sprite):
            continue
        
        _undo_redo.add_do_property(sprite, &"pixels_per_unit", value)
        _undo_redo.add_undo_property(sprite, &"pixels_per_unit", sprite.pixels_per_unit)
        
        pass
    
    _undo_redo.commit_action()
    
    pass

func _on_joint_selection_changed(
    first_selected:   int,
    selected_indexes: Array[int]) -> void:
    
    _selected_joints.clear()
    _joint_position_editor_property.read_only = true
    
    if selected_indexes.size() > 0:
        
        _selected_joints.append_array(selected_indexes.map(_joint_list.to_name))
        _joint_position_editor_property.read_only = false
        
        pass
    
    _joint_position_editor_property.update_property()
    
    pass

func _on_joint_position_property_changed(
    property: StringName,
    value:    Variant,
    field:    StringName,
    changing: bool) -> void:
    
    if _binding_sprites.size() == 0:
        return
    
    var position := Vector3(
        value.x,
        value.y,
        0
    )
    
    _undo_redo.create_action(
        "Change position of %s sprite(s)' joint(s)" % _binding_sprites.size(),
        UndoRedo.MERGE_ENDS,
        EditorInterface.get_edited_scene_root()
    )
    
    for sprite: DreamRiggerSprite in _binding_sprites:
        
        if !is_instance_valid(sprite):
            continue
        
        for joint: DreamRiggerJoint in sprite.joints:
            
            if !is_instance_valid(joint) || !_selected_joints.has(joint.name):
                continue
            
            _undo_redo.add_do_property(joint, &"position", position)
            _undo_redo.add_undo_property(joint, &"position", joint.position)
            
            pass
        
        pass
    
    _undo_redo.commit_action()
    
    pass
