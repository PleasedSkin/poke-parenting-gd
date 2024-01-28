extends TextureRect

@export var menu_parent_path: NodePath
@export var cursor_offset: Vector2

@onready var menu_parent := get_node(menu_parent_path)

var cursor_index: int = 0
var nb_elements: int = 0

func _ready() -> void:
	if menu_parent != null:
		nb_elements = menu_parent.get_child_count()
		for elt in menu_parent.get_children():
			elt.selected_by_click.connect(set_cursor_from_name)

func _process(delta):
	var input := Vector2.ZERO
	
	if Input.is_action_just_pressed("ui_up"):
		input.y -= 1
	if Input.is_action_just_pressed("ui_down"):
		input.y += 1
	if Input.is_action_just_pressed("ui_left"):
		input.x -= 1
	if Input.is_action_just_pressed("ui_right"):
		input.x += 1
	
	if menu_parent is VBoxContainer:
		set_cursor_from_index(_correct_index((cursor_index + input.y) as int % nb_elements))
	elif menu_parent is HBoxContainer:
		set_cursor_from_index(_correct_index((cursor_index + input.x) as int % nb_elements))
	elif menu_parent is GridContainer:
		set_cursor_from_index(_correct_index((cursor_index + input.x + input.y * menu_parent.columns) as int % nb_elements))
	
	if Input.is_action_just_pressed("ui_select"):
		_trigger_menu_item()


func _trigger_menu_item():
	var current_menu_item := get_menu_item_at_index(cursor_index)
		
	if current_menu_item != null:
		if current_menu_item.has_method("cursor_select"):
			current_menu_item.cursor_select()

func _correct_index(index):
	if index == -1:
		return nb_elements -1
	else:
		return index

func get_menu_item_at_index(index : int) -> Control:
	if menu_parent == null:
		return null
	
	if index >= nb_elements or index < 0:
		return null
	
	return menu_parent.get_child(index) as Control

func set_cursor_from_index(index : int) -> void:
	#print(index)
	var menu_item := get_menu_item_at_index(index)
	
	set_cursor_for_menu_item(menu_item)
	
	cursor_index = index
	
func set_cursor_from_name(name: String) -> void:
	var menu_item := get_menu_item_at_name(name)
	
	set_cursor_for_menu_item(menu_item)
	
	var future_index = menu_item.get_index()

	if (future_index == cursor_index):
		_trigger_menu_item()

	cursor_index = future_index

func set_cursor_for_menu_item(menu_item: Control):
	if menu_item == null:
		return
	
	var position = menu_item.global_position
	var size = menu_item.size
	
	global_position = Vector2(position.x, position.y + size.y / 2.0) - (size / 2.0) - cursor_offset
	

func get_menu_item_at_name(name : String) -> Control:
	if menu_parent == null:
		return null
	
	if nb_elements == 0:
		return null
	
	return menu_parent.find_child(name) as Control
