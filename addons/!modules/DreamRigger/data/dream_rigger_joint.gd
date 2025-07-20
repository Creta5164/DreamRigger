## A [Resource] that defines connection points for character rig parts,
## specifying names and positions for joint attachments.
@tool
class_name DreamRiggerJoint extends Resource

#region Properties

## Identifier for the joint.[br]
## Used to match corresponding [DreamRiggerPart3D] or [Node3D] in the hierarchy.
var name: StringName:
    get:
        return resource_name
    
    set(value):
        resource_name = value
        emit_changed()

## Representing the joint's attachment point in sprite space coordinates.
@export
var position: Vector3:
    get:
        return position
    
    set(value):
        position = value
        position.z = 0
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

## Serialized version, incremental by default.
@export_storage
var version: int:
    get:
        return version
    
    set(value):
        version = value
        emit_changed()

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
    
    var context: DreamRiggerJoint
    
    var queued_values:    Dictionary[StringName, Variant]
    var is_queue_started: bool
    
    var _finish_callback: Callable
    
    func _init(context: DreamRiggerJoint, finish_callback: Callable) -> void:
        
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
