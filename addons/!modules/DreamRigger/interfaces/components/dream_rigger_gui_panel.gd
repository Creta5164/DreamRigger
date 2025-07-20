@tool
class_name DreamRiggerGUIPanel extends Control

var _header_label:     Label
var _parent_container: SplitContainer

func _enter_tree() -> void:
    
    _header_label     = get_child(0) as Label
    _parent_container = get_parent_control() as SplitContainer

func _input(event: InputEvent) -> void:
    
    if event is InputEventMouseButton:
        
        if event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed() && event.double_click:
            
            if is_instance_valid(_header_label) && is_instance_valid(_parent_container):
                
                var label_rect := _header_label.get_global_rect()
                
                if label_rect.has_point(get_global_mouse_position()):
                    
                    var parent_size := _parent_container.size.y\
                        if   _parent_container.vertical\
                        else _parent_container.size.x
                    
                    var shrink_dead_zone_size := parent_size / 4
                    
                    var label_size := _header_label.size.y\
                        if   _parent_container.vertical\
                        else _header_label.size.x
                    
                    var target_offset = label_size
                    
                    match get_index():
                        0:
                            if _parent_container.split_offset < parent_size - shrink_dead_zone_size:
                                target_offset = parent_size - label_size
                        1:
                            if _parent_container.split_offset < shrink_dead_zone_size:
                                target_offset = parent_size - label_size
                    
                    _parent_container.split_offset = target_offset
                    _parent_container.clamp_split_offset()
                
