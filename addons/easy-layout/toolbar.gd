class_name EasyLayoutToolbar extends HBoxContainer

var EDSCALE = 1
var presets_wrapper:VBoxContainer
var plugin:EditorPlugin
var undo_redo:EditorUndoRedoManager

enum AlignPreset {
	Bottom, Center, Left, Middle, Right, Top
}
enum ArrangePreset {
	H, V, CUSTOM
}
enum SizePreset {
	Height, Width
}
const Category = {
	Align = "shape_align",
	Arrange = "arrange",
	Size = "same"
}

var picker:LayoutPresetPicker

var operation_nodes:Array[Node] = []

func _init(p_editor_scale):
	EDSCALE = p_editor_scale

func _ready() -> void:
	picker = LayoutPresetPicker.new(EDSCALE, self)
	picker.update_icons.call_deferred()
	picker.preset_selected.connect(_on_preset_selected)
	var editor_interface = plugin.get_editor_interface()
	editor_interface.get_selection().selection_changed.connect(_check_select_nodes)


func toggle_preset_picker(state:bool):
	visible = state


func _check_select_nodes():
	var editor_interface = plugin.get_editor_interface()
	var select_nodes = editor_interface.get_selection().get_selected_nodes()
	var can_layout = true
	for node in select_nodes:
		if not node.get_parent() is EasyContainer:
			can_layout = false
	if can_layout:
		operation_nodes = select_nodes
	toggle_preset_picker(can_layout)


func _on_preset_selected(p_category, p_preset):
	if p_category == Category.Align:
		_align_nodes(p_preset)
	elif p_category == Category.Size:
		_size_nodes(p_preset)
	elif p_category == Category.Arrange:
		_arrange_nodes(p_preset)


func _align_nodes(p_preset:AlignPreset):
	var align_root:Control
	var align_position:Vector2 = Vector2.ZERO
	if operation_nodes.size() > 1 :
		align_root = operation_nodes[0]
		align_position = align_root.position
	else:
		align_root = operation_nodes[0].get_parent()#parent is easy container
	
	for node in operation_nodes:
		match p_preset:
			AlignPreset.Left:
				node.position.x = align_position.x
			AlignPreset.Center:
				node.position.x = (align_position.x + align_root.size.x/2) - (node.size.x/2)
			AlignPreset.Right:
				node.position.x = (align_position.x + align_root.size.x) - node.size.x
			AlignPreset.Top:
				node.position.y = align_position.y
			AlignPreset.Middle:
				node.position.y = (align_position.y + align_root.size.y/2) - (node.size.y/2)
			AlignPreset.Bottom:
				node.position.y = (align_position.y + align_root.size.y) - node.size.y

func _size_nodes(p_preset:SizePreset):
	for node in operation_nodes:
		match p_preset:
			SizePreset.Width:
				node.size.x = operation_nodes[0].size.x
			SizePreset.Height:
				node.size.y = operation_nodes[0].size.y

func _arrange_nodes(p_preset:ArrangePreset):
	for node in operation_nodes:
		pass



func _exit_tree() -> void:
	var editor_interface = plugin.get_editor_interface()
	editor_interface.get_selection().selection_changed.disconnect(_check_select_nodes)
	operation_nodes.clear()


class EditorPresetPicker extends RefCounted:
	signal preset_selected
	
	var grid_separation = 0
	var preset_buttons = {}
	var EDSCALE = 1
	var BASE_SIZE = Vector2(30,30)


	func _init(scale):
		EDSCALE = scale
	
	
	func _add_button(p_category, p_preset, b):
		if preset_buttons.get(p_category) == null:
			preset_buttons[p_category] = {}
		preset_buttons[p_category][p_preset] = b


	func _add_row_button(p_row:HBoxContainer, p_category, p_preset, p_name):
		var b = Button.new()
		b.auto_translate = false
		b.set_custom_minimum_size(BASE_SIZE * EDSCALE)
		b.set_size(BASE_SIZE * EDSCALE)
		b.set_icon_alignment(HORIZONTAL_ALIGNMENT_CENTER)
		b.set_tooltip_text(p_name)
		b.set_flat(true)
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.expand_icon = true
		p_row.add_child.call_deferred(b)
		b.pressed.connect(_preset_button_pressed.bind(p_category, p_preset))
		_add_button(p_category, p_preset, b)
		
		
	func _add_text_button(p_row:HBoxContainer, p_category, p_preset, p_name):
		var b = Button.new()
		b.toggle_mode = true
		b.set("theme_override_font_sizes/font_size",12)
		b.set_custom_minimum_size(BASE_SIZE * EDSCALE)
		b.set_size(BASE_SIZE * EDSCALE)
		b.set_text(p_name)
		p_row.add_child(b)
		b.pressed.connect(_preset_button_pressed.bind(p_category, p_preset))
		_add_button(p_category, p_preset, b)


	func _add_separator(p_box:HBoxContainer, p_separator):
		p_separator.add_theme_constant_override("separation", grid_separation)
		p_separator.set_custom_minimum_size(Vector2(1, 1))
		p_box.add_child.call_deferred(p_separator)
	
	func _preset_button_pressed(p_category, p_preset):
		#print("catgory: ", p_category, "preset: ", p_preset)
		preset_selected.emit(p_category, p_preset)


class LayoutPresetPicker extends EditorPresetPicker:
	var state:Dictionary
	const LABEL_WIDTH = 70

	func _init(scale:float, root:HBoxContainer):
		super(scale)
		_add_row_button(root, Category.Align, AlignPreset.Left, " 左对齐 ")
		_add_row_button(root, Category.Align, AlignPreset.Center, " 左右居中对齐 ")
		_add_row_button(root, Category.Align, AlignPreset.Right, " 右对齐 ")
		_add_row_button(root, Category.Align, AlignPreset.Top, " 上对齐 ")
		_add_row_button(root, Category.Align, AlignPreset.Middle, " 上下居中对齐 ")
		_add_row_button(root, Category.Align, AlignPreset.Bottom, " 下对齐 ")
		_add_separator(root, VSeparator.new());
		_add_row_button(root, Category.Size, SizePreset.Width, " 相同宽度 ")
		_add_row_button(root, Category.Size, SizePreset.Height, " 相同高度 ")
		_add_separator(root, VSeparator.new());
		_add_row_button(root, Category.Arrange, ArrangePreset.H, " 均匀行距 ")
		_add_row_button(root, Category.Arrange, ArrangePreset.V, " 均匀列距 ")
		_add_row_button(root, Category.Arrange, ArrangePreset.CUSTOM, " 表格排列 ")
		
	
	func get_icon(prefix:String, suffix:String):
		var path = "res://addons/easy-layout/icons/%s_%s.png" % [prefix, suffix]
		return load(path)
	
	func ets(e,t):
		return e.keys()[t].to_lower()
	
	func update_icons():
		preset_buttons[Category.Align][AlignPreset.Left].icon = (get_icon(Category.Align, ets(AlignPreset, AlignPreset.Left)))
		preset_buttons[Category.Align][AlignPreset.Center].icon = (get_icon(Category.Align, ets(AlignPreset, AlignPreset.Center)))
		preset_buttons[Category.Align][AlignPreset.Right].icon = (get_icon(Category.Align, ets(AlignPreset, AlignPreset.Right)))
		preset_buttons[Category.Align][AlignPreset.Top].icon = (get_icon(Category.Align, ets(AlignPreset, AlignPreset.Top)))
		preset_buttons[Category.Align][AlignPreset.Middle].icon = (get_icon(Category.Align, ets(AlignPreset, AlignPreset.Middle)))
		preset_buttons[Category.Align][AlignPreset.Bottom].icon =(get_icon(Category.Align, ets(AlignPreset, AlignPreset.Bottom)))
		#
		preset_buttons[Category.Size][SizePreset.Width].icon = (get_icon(Category.Size, ets(SizePreset, SizePreset.Width)))
		preset_buttons[Category.Size][SizePreset.Height].icon = (get_icon(Category.Size, ets(SizePreset, SizePreset.Height)))
		#
		preset_buttons[Category.Arrange][ArrangePreset.H].icon = (get_icon(Category.Arrange, ets(ArrangePreset, ArrangePreset.H)))
		preset_buttons[Category.Arrange][ArrangePreset.V].icon = (get_icon(Category.Arrange, ets(ArrangePreset, ArrangePreset.V)))
		preset_buttons[Category.Arrange][ArrangePreset.CUSTOM].icon = (get_icon(Category.Arrange, ets(ArrangePreset, ArrangePreset.CUSTOM)))
