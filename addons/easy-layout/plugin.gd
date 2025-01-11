@tool
extends EditorPlugin
const EasyContainer = preload("res://addons/easy-layout/easy_container.gd")
const Inspector = preload("res://addons/easy-layout/inspector.gd")
const ICON_EASY_LAYOUT = preload("res://addons/easy-layout/easy-layout.svg")

var _inspector:EasyLayoutInspector
var _toolbar:EasyLayoutToolbar
var _translation:Translation

func _enter_tree() -> void:
	var	EDSCALE = get_editor_interface().get_editor_scale()
	create_translation()
	create_toolbar(EDSCALE)
	_inspector = EasyLayoutInspector.new()
	_inspector.t = _translation
	add_inspector_plugin(_inspector)
	add_custom_type("EasyContainer", "Control", EasyContainer, ICON_EASY_LAYOUT)

func create_translation():
	var locale: String = get_editor_interface().get_editor_settings().get('interface/editor/editor_language')
	var script := get_script() as Script
	var path := script.resource_path.get_base_dir().path_join("translations/%s.po" % locale)
	#_translation = ResourceLoader.load(path)


func create_toolbar(EDSCALE):
	_toolbar = EasyLayoutToolbar.new(EDSCALE)
	_toolbar.plugin = self
	_toolbar.t = _translation
	_toolbar.undo_redo = get_undo_redo()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _toolbar)

func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _toolbar)
	_toolbar.free()
	remove_inspector_plugin(_inspector)
	remove_custom_type("EasyContainer")
