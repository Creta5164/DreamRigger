## Editor class that helps using GodotEngine's not exposed editor APIs.
## 
## There's bunch of proposals in Godot repository, this class workarounds way to use not exposed APIs or features.
## [br][br]
## - [url=https://github.com/godotengine/godot-proposals/issues/169]Add recording feature and button to AnimationPlayer)[/url]
## [br]
## - [url=https://github.com/godotengine/godot-proposals/issues/3468]Expose AnimationTrackEditor and AnimationTrack* related classes)[/url]
## [br]
## - [url=https://github.com/godotengine/godot-proposals/issues/6828]Expose AnimationEditor to plugins)[/url]
## [br]
## - [url=https://github.com/godotengine/godot-proposals/issues/13097]Add AnimationServer to support registering AnimationTrack types as extensions)[/url]
@tool
class_name DreamRiggerEditorInternalsHelper

## AnimationPlayerEditor node in bottom panel.
static var animation_player_editor: Node:
    get:
        if is_instance_valid(animation_player_editor):
            return animation_player_editor
        
        animation_player_editor = EditorInterface.get_base_control().get_node(
            ^"@VBoxContainer@15/DockHSplitLeftL/DockHSplitLeftR/DockHSplitMain/@VBoxContainer@26/DockVSplitCenter/@EditorBottomPanel@7324/@VBoxContainer@7309/@AnimationPlayerEditor@10507"
        )
        
        assert(
            is_instance_valid(animation_player_editor),
            "AnimationPlayer editor is not opened, please select AnimationPlayer node."
        )
        
        return animation_player_editor

## Returns editing animation's name in AnimationPlayerEditor.
static func get_editing_animation() -> String:
    
    if !is_instance_valid(animation_player_editor):
        return ""
    
    var editing_animation_dropdown: OptionButton = animation_player_editor.get_node(^"@HBoxContainer@9347/@OptionButton@9399")
    return editing_animation_dropdown.get_item_text(editing_animation_dropdown.selected)

## Returns AnimationPlayerEditor's current time.
static func get_current_time() -> float:
    
    if !is_instance_valid(animation_player_editor):
        return 0
    
    var current_time_spin_box: SpinBox = animation_player_editor.get_node(^"@HBoxContainer@9347/@SpinBox@9374")
    return current_time_spin_box.value
