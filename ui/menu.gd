extends NinePatchRect

@onready var grid_box_container = $GridBoxContainer
@onready var cursor = $Cursor

func add_item_to_menu(item):
	grid_box_container.add_child(item)
	cursor.add_element(item.name)
