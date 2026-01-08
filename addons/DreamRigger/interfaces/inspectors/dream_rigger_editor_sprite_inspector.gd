@tool
class_name DreamRiggerEditorSpriteInspector extends Control

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
        
        _name_line_edit.editable          = value
        _offset_editor_property.read_only = !value
        _ppu_editor_property.read_only    = !value
        
        enabled = value
        
        pass

var _undo_redo := EditorInterface.get_editor_undo_redo()

@onready var _name_line_edit:   LineEdit       = %NameLineEdit
@onready var _offset_container: HFlowContainer = %OffsetContainer
@onready var _ppu_container:    HFlowContainer = %PPUContainer

var _sprites: Array[DreamRiggerSprite]

var _offset_editor_property: EditorProperty
var _ppu_editor_property:    EditorProperty

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

#region Signal methods

func _ready() -> void:
    
    _offset_editor_property = EditorInspector.instantiate_property_editor(
        self,
        TYPE_VECTOR2,
        &"_sprite_offset",
        PROPERTY_HINT_NONE,
        "",
        PROPERTY_USAGE_EDITOR,
        true
    )
    _offset_editor_property.draw_label = false
    _offset_editor_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    _ppu_editor_property = EditorInspector.instantiate_property_editor(
        self,
        TYPE_FLOAT,
        &"_sprite_pixels_per_unit",
        PROPERTY_HINT_NONE,
        "",
        PROPERTY_USAGE_EDITOR,
        true
    )
    _ppu_editor_property.draw_label = false
    _ppu_editor_property.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    
    _offset_container.add_child(_offset_editor_property)
    _ppu_container.add_child(_ppu_editor_property)
    
    _offset_editor_property.set_object_and_property(self, &"_sprite_offset")
    _ppu_editor_property.set_object_and_property(self, &"_sprite_pixels_per_unit")
    
    _name_line_edit.text_submitted.connect(_on_name_submitted)
    _offset_editor_property.property_changed.connect(_on_offset_property_changed)
    _ppu_editor_property.property_changed.connect(_on_ppu_property_changed)
    
    var context := DreamRiggerEditor.get_context()
    
    context.sprites_changed.connect(set_sprites)
    
    visibility_changed.connect(_update_content)
    
    pass

func _on_name_submitted(new_text: String) -> void:
    
    if _sprites.size() == 0:
        return
    
    _undo_redo.create_action(
        "Set name of Dream Rigger sprite(s)",
        UndoRedo.MERGE_DISABLE,
        EditorInterface.get_edited_scene_root()
    )
    
    for sprite in _sprites:
        
        var old_value: StringName = sprite.get_indexed(^"name")
        var new_value: StringName = new_text
        
        _undo_redo.add_do_property(sprite, &"name", new_value)
        _undo_redo.add_undo_property(sprite, &"name", old_value)
        
        pass
    
    _undo_redo.commit_action()
    
    pass

func _on_offset_property_changed(
    property: StringName,
    value:    Variant,
    field:    StringName,
    changing: bool) -> void:
    
    if _sprites.size() == 0:
        return
    
    _undo_redo.create_action(
        "Set offset %s of Dream Rigger sprite(s)" % field,
        UndoRedo.MERGE_ENDS,
        EditorInterface.get_edited_scene_root()
    )
    
    for sprite in _sprites:
        
        var old_value: Vector3 = sprite.get_indexed(^"offset")
        var new_value: Vector3 = old_value
        
        new_value.z = 0
        
        match field:
            "x": new_value.x = value.x
            "y": new_value.y = value.y
        
        _undo_redo.add_do_property(sprite, &"offset", new_value)
        _undo_redo.add_undo_property(sprite, &"offset", old_value)
        
        pass
    
    _undo_redo.commit_action()
    
    pass

func _on_ppu_property_changed(
    property: StringName,
    value:    Variant,
    field:    StringName,
    changing: bool) -> void:
    
    if _sprites.size() == 0:
        return
    
    _undo_redo.create_action(
        "Set pixels per unit of Dream Rigger sprite(s)" % field,
        UndoRedo.MERGE_ENDS,
        EditorInterface.get_edited_scene_root()
    )
    
    for sprite in _sprites:
        
        var old_value: float = sprite.get_indexed(^"pixels_per_unit")
        var new_value: float = old_value
        
        _undo_redo.add_do_property(sprite, &"pixels_per_unit", new_value)
        _undo_redo.add_undo_property(sprite, &"pixels_per_unit", old_value)
        
        pass
    
    _undo_redo.commit_action()
    
    pass

#endregion

#region API methods

## Set context of [DreamRiggerSprite]s.
func set_sprites(sprites: Array[DreamRiggerSprite]) -> void:
    
    for sprite in _sprites:
        
        if !is_instance_valid(sprite):
            continue
        
        sprite.changed.disconnect(_update_content)
        
        pass
    
    _sprites.clear()
    _sprites.append_array(sprites)
    
    for sprite in _sprites:
        
        sprite.changed.connect(_update_content)
        
        pass
    
    _update_content()
    
    pass

#endregion

#region Operation methods

func _update_content() -> void:
    
    if !is_visible_in_tree():
        return
    
    _name_line_edit.text = _sprite_name
    _offset_editor_property.update_property()
    _ppu_editor_property.update_property()
    
    pass

#endregion
