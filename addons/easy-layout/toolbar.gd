class_name EasyLayoutToolbar extends HBoxContainer

var EDSCALE = 1
var presets_wrapper:VBoxContainer
var plugin:EditorPlugin
var undo_redo:EditorUndoRedoManager
var t:Translation

enum AlignPreset {
	Bottom, Center, Left, Middle, Right, Top
}
enum ArrangePreset {
	H, V, CUSTOM, CUSTOM_BETWEEN
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
var _arrange_h_label:Label
var _arrange_v_label:Label
var _arrange_custom_label:Label
var _arrange_h_input:LineEdit
var _arrange_v_input:LineEdit
var _arrange_custom_input:LineEdit
var _arrange_btn:Button
var _arrange_preset:ArrangePreset
var _arrange_box:HBoxContainer

var operation_nodes:Array[Node] = []
var BASE_SIZE = Vector2(30,30)

func _init(p_editor_scale):
	EDSCALE = p_editor_scale

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	picker = LayoutPresetPicker.new(EDSCALE, self)
	picker.update_icons.call_deferred()
	picker.preset_selected.connect(_on_preset_selected)
	var editor_interface = plugin.get_editor_interface()
	editor_interface.get_selection().selection_changed.connect(_check_select_nodes)
	setup_arrange_node()


func setup_arrange_node():
	var arrange_box = HBoxContainer.new()
	_arrange_box = arrange_box
	arrange_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var separator = VSeparator.new()
	separator.add_theme_constant_override("separation", 1)
	separator.set_custom_minimum_size(Vector2(1, 1))
	arrange_box.add_child(separator)
	#
	_arrange_h_label = Label.new()
	_arrange_h_label.text = "列距:"
	arrange_box.add_child(_arrange_h_label)
	_arrange_h_input = LineEdit.new()
	_arrange_h_input.size.x = 100
	_arrange_h_input.placeholder_text = "1"
	arrange_box.add_child(_arrange_h_input)
	#
	_arrange_v_label = Label.new()
	_arrange_v_label.text = "行距:"
	arrange_box.add_child(_arrange_v_label)
	_arrange_v_input = LineEdit.new()
	_arrange_v_input.size.x = 100
	_arrange_v_input.placeholder_text = "1"
	arrange_box.add_child(_arrange_v_input)
	#
	_arrange_custom_label = Label.new()
	_arrange_custom_label.text = "列数:"
	arrange_box.add_child(_arrange_custom_label)
	_arrange_custom_input = LineEdit.new()
	_arrange_custom_input.size.x = 100
	_arrange_custom_input.placeholder_text = "1"
	arrange_box.add_child(_arrange_custom_input)

	_arrange_btn = Button.new()
	_arrange_btn.flat = true
	_arrange_btn.text = "Apply"
	_arrange_btn.pressed.connect(_on_custom_arrange)
	arrange_box.add_child(_arrange_btn)
	add_child.call_deferred(arrange_box)
	_arrange_btn.icon = load("res://addons/easy-layout/icons/apply.svg")
	_arrange_btn.set_icon_alignment(HORIZONTAL_ALIGNMENT_LEFT)
	var button_size = BASE_SIZE * EDSCALE
	button_size.x += BASE_SIZE.x+10
	_arrange_btn.set_custom_minimum_size(button_size)
	_arrange_btn.set_size(button_size)
	_arrange_btn.expand_icon = true
	#
	arrange_box.hide()
	return arrange_box


func _on_custom_arrange():
	_arrange_nodes(_arrange_preset)
	_arrange_box.hide()


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
	if p_category != Category.Arrange:
		_hide_arrange_node()
	if p_category == Category.Align:
		_align_nodes(p_preset)
	elif p_category == Category.Size:
		_size_nodes(p_preset)
	elif p_category == Category.Arrange:
		_arrange_box.show()
		_arrange_preset = p_preset
		if p_preset == ArrangePreset.H:
			_toggle_arrange_h(true)
			_toggle_arrange_v(false)
			_toggle_arrange_custom(false)
		elif p_preset == ArrangePreset.V:
			_toggle_arrange_h(false)
			_toggle_arrange_v(true)
			_toggle_arrange_custom(false)
		elif p_preset == ArrangePreset.CUSTOM:
			_toggle_arrange_h(true)
			_toggle_arrange_v(true)
			_toggle_arrange_custom(true)


func _hide_arrange_node():
	_arrange_box.hide()


func _toggle_arrange_h(state):
	_arrange_h_label.visible = state
	_arrange_h_input.visible = state
	if state:
		_arrange_h_input.grab_focus()

func _toggle_arrange_v(state):
	_arrange_v_label.visible = state
	_arrange_v_input.visible = state
	if state:
		_arrange_v_input.grab_focus()

func _toggle_arrange_custom(state):
	_arrange_custom_label.visible = state
	_arrange_custom_input.visible = state
	if state:
		_arrange_h_input.grab_focus()


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
	if operation_nodes.size() < 2:
		return
	
	var spacing_h = float(_arrange_h_input.text) if _arrange_h_input.text.is_valid_float() else 0
	var spacing_v = float(_arrange_v_input.text) if _arrange_v_input.text.is_valid_float() else 0
	var columns = int(_arrange_custom_input.text) if _arrange_custom_input.text.is_valid_int() else 1
	
	var first_node = operation_nodes[0]
	var start_pos = first_node.position
	var current_pos = start_pos
	
	match p_preset:
		ArrangePreset.H:
			print("水平")
			# 水平均匀排列
			for node in operation_nodes:
				node.position = current_pos
				current_pos.x += node.size.x + spacing_h
				
		ArrangePreset.V:
			print("垂直")
			
			# 垂直均匀排列
			for node in operation_nodes:
				node.position = current_pos
				current_pos.y += node.size.y + spacing_v
				
		ArrangePreset.CUSTOM:
			if columns < 1:
				columns = 1
			
			var row = 0
			var col = 0
			var current_x = start_pos.x
			var current_y = start_pos.y
			
			for node in operation_nodes:
				# 设置节点位置
				node.position = Vector2(current_x, current_y)
				
				# 更新下一列位置
				current_x += node.size.x + spacing_h
				col += 1
				
				# 换行处理
				if col >= columns:
					col = 0
					current_x = start_pos.x
					# 更新下一行位置（当前行最大高度 + 行距）
					var max_height_in_row = 0
					for i in range(columns):
						var idx = row * columns + i
						if idx >= operation_nodes.size():
							break
						max_height_in_row = max(max_height_in_row, operation_nodes[idx].size.y)
					current_y += max_height_in_row + spacing_v
					row += 1
					
		ArrangePreset.CUSTOM_BETWEEN:
			if columns < 1:
				columns = 1
			
			var row = 0
			var col = 0
			var current_y = start_pos.y
			
			# 计算每行的最大高度
			var row_heights = []
			for i in range(0, operation_nodes.size(), columns):
				var max_height = 0
				for j in range(columns):
					var idx = i + j
					if idx >= operation_nodes.size():
						break
					max_height = max(max_height, operation_nodes[idx].size.y)
				row_heights.append(max_height)
			
			# 排列节点
			for row_index in range(row_heights.size()):
				var row_height = row_heights[row_index]
				var row_nodes = operation_nodes.slice(row_index * columns, min((row_index + 1) * columns, operation_nodes.size()))
				
				# 计算行内总宽度
				var total_width = 0
				for node in row_nodes:
					total_width += node.size.x
				
				# 计算间距
				var available_spacing = (first_node.get_parent().size.x - total_width) / (row_nodes.size() - 1)
				var current_x = start_pos.x
				
				# 排列当前行
				for node in row_nodes:
					node.position = Vector2(current_x, current_y)
					current_x += node.size.x + available_spacing
				
				# 更新下一行位置
				current_y += row_height + spacing_v


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
		#b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
		_add_row_button(root, Category.Arrange, ArrangePreset.H, " 均匀列距 ")
		_add_row_button(root, Category.Arrange, ArrangePreset.V, " 均匀行距 ")
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
