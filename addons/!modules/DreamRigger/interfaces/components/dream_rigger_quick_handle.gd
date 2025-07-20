@tool
class_name DreamRiggerQuickHandle extends TextureRect

enum Phase {
    
    BEGIN,
    MOVE,
    SUBMIT,
    CANCEL
}

const PHASE_BEGIN  := Phase.BEGIN
const PHASE_MOVE   := Phase.MOVE
const PHASE_SUBMIT := Phase.SUBMIT
const PHASE_CANCEL := Phase.CANCEL

signal drag_performed(Phase, mouse_delta: Vector2)

var _label: Label

var label_text: String:
    get:
        return label_text
    
    set(value):
        label_text = value
        _update_label()

var _captured_mouse_mode:     Input.MouseMode
var _last_mouse_position:     Vector2
var _dragging_mouse_position: Vector2

var use_relative_delta: bool

var _is_dragging := false

func _ready() -> void:
    
    _label = get_node(^"Label")
    _update_label()
    
    pass

func _exit_tree() -> void:
    
    if _is_dragging:
        Input.mouse_mode = _captured_mouse_mode
    
    _is_dragging = false
    
    pass

func _update_label() -> void:
    
    if is_instance_valid(_label):
        _label.text = label_text
    
    pass

func _gui_input(event: InputEvent) -> void:
    
    if !is_visible_in_tree():
        return
    
    if event is InputEventMouseButton:
        
        match event.button_index:
            
            MOUSE_BUTTON_LEFT:
                
                _on_pressed(event.is_pressed())
                pass
            
            MOUSE_BUTTON_RIGHT:
                
                if _is_dragging && event.is_pressed():
                    
                    _end_drag()
                    drag_performed.emit(Phase.CANCEL, Vector2.ZERO)
                
                pass
    
    if event is InputEventMouseMotion:
        
        if !_is_dragging:
            return
        
        var delta: Vector2 = event.relative
        
        if event.shift_pressed:
            delta /= 10
        
        _dragging_mouse_position += delta
        drag_performed.emit(Phase.MOVE, _dragging_mouse_position)
        Input.warp_mouse.call_deferred(_last_mouse_position)
    
    if event is InputEventKey && event.is_pressed():
        
        if _is_dragging && event.is_action("ui_cancel", true):
            
            _end_drag()
            drag_performed.emit(Phase.CANCEL, Vector2.ZERO)
    
    pass

func _on_pressed(is_pressed: bool) -> void:
    
    if !_is_dragging:
        
        if is_pressed:
            
            _begin_drag()
            drag_performed.emit(Phase.BEGIN, Vector2.ZERO)
        
    elif !is_pressed:
        
        _end_drag()
        
        if !_dragging_mouse_position.is_zero_approx():
            drag_performed.emit(Phase.SUBMIT, _dragging_mouse_position)
        
        else:
            drag_performed.emit(Phase.CANCEL, Vector2.ZERO)
    
    pass

func _begin_drag() -> void:
    
    if _is_dragging:
        return
    
    _is_dragging = true
    
    _captured_mouse_mode = Input.mouse_mode
    _last_mouse_position = get_global_mouse_position()
    Input.mouse_mode     = Input.MOUSE_MODE_CAPTURED
    
    _dragging_mouse_position = Vector2.ZERO
    
    pass

func _end_drag() -> void:
    
    if !_is_dragging:
        return
    
    _is_dragging = false
    
    Input.mouse_mode = _captured_mouse_mode
    Input.warp_mouse.call_deferred(_last_mouse_position)
    
    pass
