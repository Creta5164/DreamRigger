@tool
class_name DreamRiggerPosePreviewer extends DreamRiggerGUIPanel

const EMPTY_SPRITE: Texture2D = preload("res://addons/!modules/DreamRigger/resources/empty_sprite.png")

var _binding_part: Node

var _pose_viewer:     TextureRect
var _pose_name_label: Label

func _enter_tree() -> void:
    
    super._enter_tree()
    
    _pose_viewer     = %"PoseViewer"
    _pose_name_label = %"PoseNameLabel"
    
    pass

func _exit_tree() -> void:
    
    unbind_part()
    
    pass

func bind_part(part: Node) -> void:
    
    if part is not DreamRiggerPart2D && part is not DreamRiggerPart3D:
        return
    
    if _binding_part == part:
        return
    
    unbind_part()
    
    _binding_part = part
    
    refresh()
    
    if !is_instance_valid(part):
        return
    
    if !part.tree_entered.is_connected(refresh):
        part.tree_entered.connect(refresh)
    
    if !part.tree_exited.is_connected(refresh):
        part.tree_exited.connect(refresh)
    
    if !part.pose_changed.is_connected(_on_pose_changed):
        part.pose_changed.connect(_on_pose_changed)
    
    if !part.pose_modified.is_connected(_on_pose_modified):
        part.pose_modified.connect(_on_pose_modified)
    
    if !part.sprite_changed.is_connected(_on_sprite_changed):
        part.sprite_changed.connect(_on_sprite_changed)
    
    pass

func unbind_part() -> void:
    
    if !is_instance_valid(_binding_part):
        return
    
    if _binding_part.tree_entered.is_connected(refresh):
        _binding_part.tree_entered.disconnect(refresh)
    
    if _binding_part.tree_exited.is_connected(refresh):
        _binding_part.tree_exited.disconnect(refresh)
    
    if _binding_part.pose_changed.is_connected(_on_pose_changed):
        _binding_part.pose_changed.disconnect(_on_pose_changed)
    
    if _binding_part.pose_modified.is_connected(_on_pose_modified):
        _binding_part.pose_modified.disconnect(_on_pose_modified)
    
    if _binding_part.sprite_changed.is_connected(_on_sprite_changed):
        _binding_part.sprite_changed.disconnect(_on_sprite_changed)
    
    _binding_part = null
    
    pass

func _on_part_tree_entered() -> void:
    
    pass

func _on_part_tree_exited() -> void:
    
    pass

func _on_pose_changed(pose: DreamRiggerPose) -> void:
    
    refresh()
    
    pass

func _on_pose_modified(pose: DreamRiggerPose) -> void:
    
    refresh()
    
    pass

func _on_sprite_changed(sprite: DreamRiggerSprite) -> void:
    
    refresh()
    
    pass

func refresh() -> void:
    
    _pose_viewer.texture_filter = CanvasItem.TextureFilter.TEXTURE_FILTER_PARENT_NODE
    
    if is_instance_valid(_binding_part):
        
        if _binding_part is DreamRiggerPart2D || _binding_part is DreamRiggerPart3D:
            
            _pose_viewer.texture_filter = (_binding_part.texture_filter + 1)\
                as CanvasItem.TextureFilter
    
    update_preview()
    
    pass

func update_preview(texture: Texture2D = null, name: String = "") -> void:
    
    if !is_instance_valid(texture):
        
        if !is_instance_valid(_binding_part) || !_binding_part.is_inside_tree():
            
            _pose_viewer.texture  = null
            _pose_name_label.text = ""
            return
        
        var sprite: DreamRiggerSprite = _binding_part.sprite
        
        if is_instance_valid(sprite):
            
            texture = sprite.texture
            
            var pose_uid: int = _binding_part.pose_uid
            
            var pose_index := 0
            
            if is_instance_valid(_binding_part.pose):
                pose_index = _binding_part.pose.uid_to_index(pose_uid)
            
            #FIXME: 포즈 브라우저 인덱스와 통일시켜야 함.
            name = "[%s] %s" % [ pose_index, sprite.resource_name ]
    
    _pose_viewer.texture = texture\
        if is_instance_valid(texture)\
        else EMPTY_SPRITE
    
    _pose_name_label.text = name
    
    pass