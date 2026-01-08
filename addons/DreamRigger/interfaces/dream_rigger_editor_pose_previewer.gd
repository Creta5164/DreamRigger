## An editor [DreamRiggerEditorGUIPanel] control class for previewing [DreamRiggerSprite] in [DreamRiggerEditorControlPanel].
@tool
class_name DreamRiggerEditorPosePreviewer extends DreamRiggerEditorGUIPanel

#region Constants

## Empty sprite.
const EMPTY_SPRITE: Texture2D = preload("../resources/empty_sprite.png")

#endregion

#region Members

@onready var _texture_rect: TextureRect = %PoseViewer
@onready var _name_label:   Label       = %PoseNameLabel

#endregion

#region API methods

## Set sprite to show preview.
func set_sprite_preview(sprite: DreamRiggerSprite) -> void:
    
    if !is_instance_valid(sprite):
        
        _texture_rect.texture = null
        _name_label.text      = ""
        return
    
    if is_instance_valid(sprite.texture):
        _texture_rect.texture = sprite.texture
    
    else:
        _texture_rect.texture = EMPTY_SPRITE
    
    var context    := DreamRiggerEditor.get_context()
    var part_nodes := context.part_nodes
    
    var part_nodes_count := part_nodes.size()
    
    if part_nodes_count == 0:
        _name_label.text = "[res] %s" % sprite.name
    
    elif part_nodes_count == 1:
        
        var part_node := part_nodes.front()
        
        var pose:     DreamRiggerPose = part_node.get(&"pose")
        var pose_uid: int             = part_node.get(&"pose_uid")
        
        var pose_index := 0
        
        if is_instance_valid(pose):
            pose_index = pose.uid_to_index(pose_uid)
        
        _name_label.text = "[%s] %s" % [ pose_index, sprite.name ]
    
    else:
        _name_label.text = "[*] %s" % sprite.name
    
    pass

#endregion
