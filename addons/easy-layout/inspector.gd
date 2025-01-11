class_name EasyLayoutInspector extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
	if not object is Control: return false
	var parent = (object as Control).get_parent()
	return parent is EasyContainer
