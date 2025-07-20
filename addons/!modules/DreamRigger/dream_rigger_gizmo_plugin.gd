@tool
class_name DreamRiggerGizmoPlugin extends EditorNode3DGizmoPlugin

func _init() -> void:
    
    create_handle_material("joint_handle")
    
    pass

func _get_gizmo_name() -> String:
    return "DreamRigger Joints"

func _has_gizmo(for_node_3d: Node3D) -> bool:
    return true

func _create_gizmo(for_node_3d: Node3D) -> EditorNode3DGizmo:
    return DreamRiggerJointGizmo.new()
