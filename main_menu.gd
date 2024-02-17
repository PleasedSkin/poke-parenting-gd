extends Node2D


var game_scene 

func _ready() -> void:
    game_scene = preload("res://game.tscn")




func _on_button_pressed() -> void:
    get_tree().change_scene_to_packed(game_scene)
    PokeParentingEvents.emit_signal("reset_required")
