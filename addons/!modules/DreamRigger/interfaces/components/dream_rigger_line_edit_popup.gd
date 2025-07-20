#This script has part of GodotEngine source code due cover editor feature with polyfill.
#https://github.com/godotengine/godot/blob/e5ccaa79e2a2d5551369bd6cc1f8ed654a791275/scene/gui/tree.cpp#L6579-L6600
#**************************************************************************#
#* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). *#
#* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  *#
#*                                                                        *#
#* Permission is hereby granted, free of charge, to any person obtaining  *#
#* a copy of this software and associated documentation files (the        *#
#* "Software"), to deal in the Software without restriction, including    *#
#* without limitation the rights to use, copy, modify, merge, publish,    *#
#* distribute, sublicense, and/or sell copies of the Software, and to     *#
#* permit persons to whom the Software is furnished to do so, subject to  *#
#* the following conditions:                                              *#
#*                                                                        *#
#* The above copyright notice and this permission notice shall be         *#
#* included in all copies or substantial portions of the Software.        *#
#*                                                                        *#
#* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        *#
#* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     *#
#* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. *#
#* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   *#
#* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   *#
#* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      *#
#* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 *#
#**************************************************************************#

class_name DreamRiggerLineEditPopup extends Popup

var _vb:           VBoxContainer
var _line_editor:  LineEdit
#var _text_editor:  TextEdit
#var _value_editor: HSlider

var _callback: Callable

func _init() -> void:
    
    _vb = VBoxContainer.new()
    _vb.add_theme_constant_override("separation", 0)
    _vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    self.add_child(_vb)
    
    _line_editor = LineEdit.new()
    _line_editor.set_v_size_flags(Control.SIZE_EXPAND_FILL)
    _line_editor.hide()
    _vb.add_child(_line_editor)
    
    #_text_editor = TextEdit.new()
    #_text_editor.set_v_size_flags(Control.SIZE_EXPAND_FILL)
    #_text_editor.hide()
    #_vb.add_child(_text_editor)
    
    #_value_editor = HSlider.new()
    #_value_editor.set_v_size_flags(Control.SIZE_EXPAND_FILL)
    #_value_editor.hide()
    #_vb.add_child(_value_editor)
    
    _line_editor.text_submitted.connect(_line_editor_submit)
    
    hide()
    
    pass

func show_context(global_rect: Rect2, initial_value: String, callback: Callable) -> void:
    
    _callback = callback
    
    var popup_rect: Rect2
    
    popup_rect.position = global_rect.position
    popup_rect.size = global_rect.size
    
    if is_layout_rtl():
        popup_rect.position.x = get_size().x - popup_rect.position.x - popup_rect.size.x
    
    _line_editor.clear()
    _line_editor.set_text(initial_value)
    _line_editor.select_all()
    _line_editor.show()
    
    set_position(popup_rect.position)
    set_size(popup_rect.size)
    
    # Below codes not used due minimum requirement for now.
    #set_size(popup_rect.size * popup_scale)
    #if !is_embedded():
    #    set_content_scale_factor(popup_scale)
    
    popup()
    child_controls_changed()
    
    _line_editor.grab_focus()
    
    pass

func _line_editor_submit(p_text: String) -> void:
    
    hide()
    _callback.call(p_text)
    
    pass
