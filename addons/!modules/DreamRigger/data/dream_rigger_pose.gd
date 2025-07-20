## A [Resource] that manages a collection of [DreamRiggerSprite] resources for character animation poses.
@tool
class_name DreamRiggerPose extends Resource

const UID_MIN_VALUE := 1000000000
const UID_MAX_VALUE := 9999999999

#region Properties

## An [Dictionary] of [DreamRiggerSprite] resources representing different visual states for a character part.
@export
var sprites: Dictionary[int, DreamRiggerSprite]:
    get:
        return sprites
    
    set(value):
        sprites = value
        _on_sprites_changed()

var _is_migrating: bool
## An [Dictionary] of [DreamRiggerSprite] resources representing different visual states for a character part.
## @deprecated: Use [sprites] instead.
@export_storage
var _sprites: Dictionary[int, DreamRiggerSprite]:
    get:
        return _sprites
    
    set(value):
        _sprites = value

## Serialized version, incremental by default.
@export_storage
var version: int:
    get:
        return version
    
    set(value):
        version = value
        emit_changed()

func _get_property_list() -> Array[Dictionary]:
    
    var properties: Array[Dictionary] = []
    
    properties.append({
        "name": "name",
        "type": TYPE_STRING,
        "hint": PROPERTY_HINT_NONE,
        "usage": PROPERTY_USAGE_EDITOR
    })
    
    return properties

#endregion

#region Signal methods

func _init() -> void:
    
    if version != DreamRiggerMetadata.VERSION:
        
        #if version < 1:
        #    #TODO: Do migrate logic with deferred call.
        
        version = DreamRiggerMetadata.VERSION
    
    pass

func _on_sprites_changed() -> void:
    
    if !Engine.is_editor_hint():
        return
    
    var sprite_created := false
    
    var last_valid_sprite := _get_last_valid_sprite()
    
    for uid in sprites:
        
        if is_instance_valid(sprites[uid]):
            continue 
        
        if sprites.size() == 1:
            sprites[uid] = DreamRiggerSprite.new()
            sprite_created = true
            continue
        
        if !is_instance_valid(last_valid_sprite):
            continue
        
        #https://github.com/godotengine/godot/issues/74918
        #직접 리소스를 복제해야함...
        sprites[uid] = last_valid_sprite._duplicate_manually()
        sprite_created = true
        pass
    
    if sprite_created:
        notify_property_list_changed()
    
    _reassign_sprites_event()
    emit_changed.call_deferred()
    
    pass

func _reassign_sprites_event() -> void:
    
    if !Engine.is_editor_hint():
        return
    
    if sprites.size() == 0:
        return
    
    for sprite in sprites.values():
        
        if !is_instance_valid(sprite):
            continue
        
        if sprite.changed.is_connected(emit_changed):
            sprite.changed.disconnect(emit_changed)
        
        sprite.changed.connect(emit_changed)
        
        pass
    
    pass

#endregion

#region Methods

## Returns a [DreamRiggerSprite] at the specified UID.[br]
## Returns null if the sprite array is empty or UID is not exist.
func get_sprite(uid: int) -> DreamRiggerSprite:
    
    if sprites.size() == 0:
        return null
    
    if !sprites.has(uid):
        return null
    
    return sprites[uid]

## An utility method for handling sprites with index.
## Note : Dictionary is likely not intended to use ordered by default, use it with caution.
func uid_to_index(uid: int) -> int:
    
    if sprites.size() == 0:
        return -1
    
    return sprites.keys().find(uid)

## An utility method for handling sprites with index.
## Note : Dictionary is likely not intended to use ordered by default, use it with caution.
func index_to_uid(index: int) -> int:
    
    if index < 0 || index >= sprites.size():
        return 0
    
    return sprites.keys()[index]

func _add_sprite_with_uid(uid: int, sprite: DreamRiggerSprite) -> void:
    
    if !Engine.is_editor_hint():
        return
    
    sprites[uid] = sprite
    _on_sprites_changed()
    
    pass

func _add_sprite_at_with_uid(uid: int, sprite: DreamRiggerSprite, index: int) -> void:
    
    if !Engine.is_editor_hint():
        return
    
    var sprites_count := self.sprites.size()
    
    if sprites_count == 0 || sprites_count == index:
        
        _add_sprite_with_uid(uid, sprite)
        return
    
    if index < 0 || index > sprites_count:
        return
    
    var current_sprites := self.sprites
    var sprites: Dictionary[int, DreamRiggerSprite]
    
    var iteration_index := 0
    
    for current_sprite_uid: int in current_sprites:
        
        if iteration_index == index:
            sprites[uid] = sprite
        
        sprites[current_sprite_uid] = current_sprites[current_sprite_uid]
        iteration_index += 1
    
    self.sprites = sprites
    
    pass

func _remove_sprite_by_uid(uid: int) -> void:
    
    if !Engine.is_editor_hint():
        return
    
    if !sprites.has(uid):
        return
    
    sprites.erase(uid)
    _on_sprites_changed()
    
    pass

func _get_last_valid_sprite() -> DreamRiggerSprite:
    
    var uids := sprites.keys()
    
    var last_valid_sprite_index := uids.rfind_custom(
    func(uid: int) -> bool:
        return is_instance_valid(sprites[uid])
    )
    
    if last_valid_sprite_index == -1:
        return null
    
    return sprites[uids[last_valid_sprite_index]]

func _create_uid() -> int:
    
    var duplicated_iteration_count := 100
    var new_id: int = 0
    
    while duplicated_iteration_count > 0:
        
        duplicated_iteration_count -= 1
        new_id = randi_range(UID_MIN_VALUE, UID_MAX_VALUE)
        
        if !_sprites.has(new_id):
            break
        
        pass
    
    assert(
        duplicated_iteration_count > 0,
        "[DreamRiggerPose] Maximum UID create iteration count reached."
    )
    
    return new_id

#endregion

#region Migration

## Handles version control that makes old version up to date.
var _migration_context := MigrationContext.new(
        self,
        _on_migration_finished
    )

func _on_migration_finished() -> void:
    
    #TODO: Write finalization logic here for after migration if necessary.
    
    _migration_context = null
    
    pass

func _set(property: StringName, value: Variant) -> bool:
    
    if _migration_context != null:
        _migration_context.queue_property(property, value)
    
    return false

class MigrationContext extends RefCounted:
    
    var context: DreamRiggerPose
    
    var queued_values:    Dictionary[StringName, Variant]
    var is_queue_started: bool
    
    var _finish_callback: Callable
    
    func _init(context: DreamRiggerPose, finish_callback: Callable) -> void:
        
        self.context     = context
        _finish_callback = _finish_callback
        
        pass
    
    func queue_property(property_name: StringName, value: Variant) -> void:
        
        set_property(property_name, value)
        
        if !is_queue_started:
            
            is_queue_started = true
            _process.call_deferred()
        
        pass
    
    func _process() -> void:
        
        if !is_instance_valid(context):
            return
        
        if context.version >= DreamRiggerMetadata.VERSION:
            
            context._migration_context = null
            return
        
        while context.version < DreamRiggerMetadata.VERSION:
            
            _migrate(context.version)
            context.version += 1
            
            pass
        
        for property_name: StringName in queued_values:
            
            if property_name == &"version":
                continue
            
            context.set(property_name, queued_values[property_name])
            
            pass
        
        if is_instance_valid(_finish_callback):
            _finish_callback.call()
        
        context._migration_context = null
        
        pass
    
    func _migrate(current_version: int) -> void:
        
        match DreamRiggerMetadata.to_semantic_version(current_version):
            
            #TODO: Write migration logic here if necessary.
            
            pass
        
        pass
    
    func get_property(name: StringName) -> Variant:
        
        return queued_values[name]\
            if queued_values.has(name)\
          else null
    
    func set_property(name: StringName, value: Variant) -> void:
        
        queued_values[name] = value
        
        pass
    
    func move_property(from: StringName, to: StringName) -> void:
        
        set_property(to, delete_property(from))
        
        pass
    
    func delete_property(name: StringName) -> Variant:
        
        var value := get_property(name)
        queued_values.erase(name)
        
        return value
    
    pass

#endregion
