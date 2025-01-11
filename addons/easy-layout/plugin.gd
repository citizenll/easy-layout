@tool
extends EditorPlugin
const EasyContainer = preload("res://addons/easy-layout/easy_container.gd")
const Inspector = preload("res://addons/easy-layout/inspector.gd")
const ICON_EASY_LAYOUT = preload("res://addons/easy-layout/easy-layout.svg")

var _inspector:EasyLayoutInspector
var _toolbar:EasyLayoutToolbar

func _enter_tree() -> void:
	var	EDSCALE = get_editor_interface().get_editor_scale()
	create_toolbar(EDSCALE)
	_inspector = EasyLayoutInspector.new()
	add_inspector_plugin(_inspector)
	add_custom_type("EasyContainer", "Control", EasyContainer, ICON_EASY_LAYOUT)


func create_toolbar(EDSCALE):
	_toolbar = EasyLayoutToolbar.new(EDSCALE)
	_toolbar.plugin = self
	_toolbar.undo_redo = get_undo_redo()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _toolbar)

func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _toolbar)
	_toolbar.free()
	remove_inspector_plugin(_inspector)
	remove_custom_type("EasyContainer")
