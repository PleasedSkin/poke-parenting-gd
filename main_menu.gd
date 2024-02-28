extends Node2D


var game_scene 

func _ready() -> void:
	game_scene = preload("res://game.tscn")


func _on_new_game_button_pressed() -> void:
	_instanciate_game_scene_with_potential_load(false)


func _on_load_game_button_pressed() -> void:
	_instanciate_game_scene_with_potential_load(true)


func _instanciate_game_scene_with_potential_load(load_required: bool):
	get_tree().change_scene_to_packed(game_scene)
	PokeParentingEvents.load_required = load_required
