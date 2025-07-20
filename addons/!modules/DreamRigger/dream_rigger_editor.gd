@tool
class_name DreamRiggerEditor extends EditorPlugin

const CONTROL_PANEL := preload("res://addons/!modules/DreamRigger/interfaces/control_panel/dream_rigger_control_panel.tscn")
const SIGNAL_ANIMATION_SELECTED := &"animation_selected"

static var instance: DreamRiggerEditor

var control_panel: DreamRiggerControlPanel

var gizmo: DreamRiggerGizmoPlugin

var scene_tree: Tree

## Closes control panel
static func close_control_panel() -> void:
    if is_instance_valid(instance):
        instance._close_control_panel()

## Opens control panel, it attached bottom right of left side panel by default.
static func open_control_panel(part: Node = null) -> void:
    if is_instance_valid(instance):
        instance._open_control_panel(part)

func _enter_tree() -> void:
    
    instance = self
    
    gizmo = DreamRiggerGizmoPlugin.new()
    add_node_3d_gizmo_plugin(gizmo)
    
    _open_control_panel()
    
    pass

func _exit_tree() -> void:
    
    if instance == self:
        instance = null
    
    _close_control_panel()
    
    if is_instance_valid(gizmo):
        remove_node_3d_gizmo_plugin(gizmo)
        gizmo = null
    
    pass

func _on_editor_animation_selected(path: String) -> void:
    
    pass

func _open_control_panel(part: Node = null) -> void:
    
    _close_control_panel()
    
    await get_tree().process_frame
    
    if !control_panel:
        control_panel = CONTROL_PANEL.instantiate()
    
    add_control_to_dock(DOCK_SLOT_LEFT_BR, control_panel)
    
    pass

func _close_control_panel() -> void:
    
    if control_panel:
        remove_control_from_docks(control_panel)
        control_panel.queue_free()
    
    pass