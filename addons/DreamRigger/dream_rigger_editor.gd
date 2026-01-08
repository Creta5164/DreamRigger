## DreamRigger's editor plugin.
## 
## This provides open or close control panel and get context by [method get_context]
## for querying current context related nodes or resources.
@tool
class_name DreamRiggerEditor extends EditorPlugin

## DreamRigger's editor control panel scene.
const CONTROL_PANEL := preload("./interfaces/dream_rigger_editor_control_panel.tscn")

#region Members

## Singleton instance of editor.
static var instance: DreamRiggerEditor

var _control_panel: Control
var _context: DreamRiggerEditorContext

var _is_inserting_animation_key:   bool
var _halt_selection_change_action: bool

#endregion

#region API

## Returns editor context that used for managing context and editor operations.
static func get_context() -> DreamRiggerEditorContext:
    return instance._context\
        if instance\
        else null

## Opens control panel, it attached bottom right of left side panel([constant EditorPlugin.DOCK_SLOT_LEFT_BR]) by default.
static func open_control_panel(part: Node = null) -> void:
    
    if is_instance_valid(instance):
        instance._open_control_panel(part)
    
    pass

## Closes control panel.
static func close_control_panel() -> void:
    
    if is_instance_valid(instance):
        instance._close_control_panel()
    
    pass

## Validates given node is not [code]null[/code] and checks it's [DreamRiggerPart2D] or [DreamRiggerPart3D].
static func is_part_node_valid(node: Node) -> bool:
    return (
        is_instance_valid(node)
     && (node is DreamRiggerPart2D || node is DreamRiggerPart3D)
    )

## Finds parent part.
## [br][br]
## This will returns root part when [param find_root] is [code]true[/code],
## and you can specify end node of recursive lookup with [param topmost_node],
## [member Tree.root] from given [param node] will be used if it's [code]null[/code] (default).
static func find_parent_part(node: Node, find_root: bool = false, topmost_node: Node = null) -> Node:
    
    if !is_instance_valid(topmost_node):
        topmost_node = node.get_tree().root
    
    if !is_instance_valid(node) || node == topmost_node:
        return null
    
    if node is DreamRiggerPart2D || node is DreamRiggerPart3D:
        
        if !find_root || (find_root && node.is_root_part):
            return node
    
    var parent: Node = node.get_parent()
    
    return find_parent_part(parent, find_root, topmost_node)

#endregion

#region Signal methods

func _enter_tree() -> void:
    
    _context = DreamRiggerEditorContext.new()
    instance = self
    
    _open_control_panel()
    
    pass

func _exit_tree() -> void:
    
    if is_instance_valid(_context):
        _context = null
    
    if instance == self:
        instance = null
    
    _close_control_panel()
    
    pass

func _ready() -> void:
    
    var editor_interface := get_editor_interface()
    var selection := editor_interface.get_selection()
    
    selection.selection_changed.connect(_on_selection_changed.bind(selection))
    
    pass

func _on_selection_changed(selection: EditorSelection) -> void:
    
    var selected_nodes := selection.get_selected_nodes()
    
    var animation_player_index := selected_nodes.find_custom(
        func(node: Node) -> bool: return node is AnimationPlayer
    )
    
    if animation_player_index != -1:
        _context.set_recording_animation_player(
            selected_nodes[animation_player_index] as AnimationPlayer
        )
    
    var part_nodes := selection.get_selected_nodes()\
        .filter(DreamRiggerEditor.is_part_node_valid)
    
    if part_nodes.size() == 0:
        return
    
    if !_halt_selection_change_action:
        
        var undo_redo := EditorInterface.get_editor_undo_redo()
        
        undo_redo.create_action(
            "Select Dream Rigger Part(s)",
            UndoRedo.MERGE_DISABLE,
            EditorInterface.get_edited_scene_root()
        )
        
        undo_redo.add_do_method(selection, &"clear")
        
        for part_node in part_nodes:
            undo_redo.add_do_method(selection, &"add_node", part_node)
        
        undo_redo.add_do_property(self, &"_halt_selection_change_action", true)
        
        undo_redo.add_undo_method(selection, &"clear")
        
        for part_node in _context.part_nodes:
            undo_redo.add_undo_method(selection, &"add_node", part_node)
        
        undo_redo.add_undo_property(self, &"_halt_selection_change_action", true)
        
        undo_redo.commit_action(false)
        pass
    
    _context.set_part_context(part_nodes, false)
    _halt_selection_change_action = false
    
    pass

#endregion

#region Methods

func _open_control_panel(part: Node = null) -> void:
    
    _close_control_panel()
    
    await get_tree().process_frame
    
    if !_control_panel:
        _control_panel = CONTROL_PANEL.instantiate()
    
    add_control_to_dock(DOCK_SLOT_LEFT_BR, _control_panel)
    
    pass

func _close_control_panel() -> void:
    
    if _control_panel:
        remove_control_from_docks(_control_panel)
        _control_panel.queue_free()
    
    pass

#endregion
