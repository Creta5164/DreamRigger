class_name DreamRiggerMetadata

const VERSION: int = 2

const SEMANTIC_VERSION: StringName = &"alpha-0.1.1"

#TODO: Should be auto-generated.
static func to_semantic_version(version: int) -> StringName:
    
    match version:
        1: return &"alpha-0.1.0"
        
        #Marking it latest, requires add previous VERSION with-
        #semantic version name before this if increases.
        VERSION: return SEMANTIC_VERSION
        
        pass
    
    return &"UNKNOWN"