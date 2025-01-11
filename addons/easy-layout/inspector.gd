class_name EasyLayoutInspector extends EditorInspectorPlugin

var t:Translation

func _can_handle(object: Object) -> bool:
	if not object is Control: return false
	var parent = (object as Control).get_parent()
	return parent is EasyContainer
