extends RichTextLabel
class_name MenuItem

signal cursor_selected
signal selected_by_click(name: String)

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func cursor_select():
	emit_signal("cursor_selected")


func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		emit_signal("selected_by_click", name)
