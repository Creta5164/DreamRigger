## A metadata for DreamRigger related Resources/Node that requires versioning for future.
class_name DreamRiggerMetadata

## Incremental constant version.
## [br][br]
## This version is a value that helps to version while making the size of serialized resources lighter.
## [br]
## When the version changes, this value must be increased and
## must be able to be converted to a semantic version in [method to_semantic_version].
const VERSION: int = 3

## Semantic flavored constant version.
## [br][br]
## This version is intended to indicate which version of DreamRigger is currently in use,
## and is also intended to help humans understand migration logic within Resources/Node.
const SEMANTIC_VERSION: StringName = &"alpha-0.2.0"

## Returns a human-readable semantic version of the given incremental version value as a [StringName].
## [br][br]
## [param version] must be an incremental version value,
## and if not previously defined, returns [code]&"UNKNOWN"[/code].
static func to_semantic_version(version: int) -> StringName:
    
    #TODO: Should be auto-generated.
    
    match version:
        1: return &"alpha-0.1.0"
        2: return &"alpha-0.1.1"
        
        #Marking it latest, requires add previous VERSION with-
        #semantic version name before this if increases.
        VERSION: return SEMANTIC_VERSION
        
        pass
    
    return &"UNKNOWN"
