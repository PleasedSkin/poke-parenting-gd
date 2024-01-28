extends RichTextLabel
class_name MenuItem

signal selected_by_click(name: String)

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func cursor_select():
	PokeParentingEvents.emit_signal("main_item_selected", name)


func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton && event.pressed && event.button_index == 1):
		emit_signal("selected_by_click", name)
