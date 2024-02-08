extends Node2D


@onready var get_pokemon_request := %GetPokemon
@onready var get_pokemon_species_request := %GetPokemonSpecies
@onready var get_pokemon_pic_request := %GetPokemonPic
@onready var texture_rect = %TextureRect as TextureRect
@onready var pokemon_name_label = %Name
@onready var pokemon_level = %Niveau
@onready var menu_principal = %MenuPrincipal
@onready var main_container = %VBoxContainer
@onready var bouton_retour = %Retour
var current_special_menu

const POKE_API_URL := "https://pokeapi.co/api/v2/"

var pokemon_number: int

var rng = RandomNumberGenerator.new()

var main_menu

func _ready() -> void:
	main_menu = preload("res://ui/menu_principal.tscn").instantiate()
	get_pokemon_request.request_completed.connect(_on_pokemon_request_completed)
	get_pokemon_species_request.request_completed.connect(_on_pokemon_species_request_completed)
	get_pokemon_pic_request.request_completed.connect(_on_pokemon_pic_request_completed)
	PokeParentingEvents.points_emitted.connect(_on_poke_parenting_events_points_emitted)
	PokeParentingEvents.main_item_selected.connect(_on_poke_parenting_events_main_item_selected)
	#_generate_random_pokemon()

func _generate_random_pokemon() -> void:
	pokemon_number = rng.randi_range(1, 1025)
	get_pokemon_request.request(POKE_API_URL + "pokemon/" + str(pokemon_number))
	get_pokemon_species_request.request(POKE_API_URL + "pokemon-species/" + str(pokemon_number))

func _on_pokemon_request_completed(result, response_code, headers, body):
	if response_code == HTTPClient.RESPONSE_OK:
		var pokemon = JSON.parse_string(body.get_string_from_utf8())
		# print(pokemon["name"])
		get_pokemon_pic_request.request(pokemon["sprites"]["front_default"])
	else:
		print_debug("Erreur lors de la récupération du pokémon " + str(pokemon_number))


func _on_pokemon_pic_request_completed(result, response_code, headers, body):
	if response_code == HTTPClient.RESPONSE_OK:
		var image = Image.new()
		var resultat_chargement = image.load_png_from_buffer(body)
		if resultat_chargement != OK:
			print_debug("Erreur lors du chargement de l'image du pokémon " + str(pokemon_number))
		else:
			var texture = ImageTexture.create_from_image(image)
			texture.set_size_override(Vector2i(200, 200))
			
			texture_rect.texture = texture
	else:
		print_debug("Erreur lors de la récupération de l'image du pokémon " + str(pokemon_number))
	

func _on_pokemon_species_request_completed(result, response_code, headers, body):
	if response_code == HTTPClient.RESPONSE_OK:
		var pokemon_species = JSON.parse_string(body.get_string_from_utf8())
		var corresponding_item = pokemon_species["names"].filter(func(name): return name.language.name == "fr")[0]
		pokemon_name_label.text = "[center]" + corresponding_item.name + "[/center]"
	else:
		print_debug("Erreur lors de la récupération des données d'espèce pokémon " + str(pokemon_number))


func _on_button_pressed() -> void:
	_generate_random_pokemon()
	
func _on_poke_parenting_events_points_emitted(nb_points: int) -> void:
	pokemon_level.text = "[center]Niveau : " + str(nb_points) + "[/center]"


func _on_poke_parenting_events_main_item_selected(name: String):
	var pos = menu_principal.global_position
	# main_container.remove_child(menu_principal)
	menu_principal.visible = false
	menu_principal.process_mode = Node.PROCESS_MODE_DISABLED
	current_special_menu = load("res://ui/menus_categorises/" + name.to_lower() + ".tscn").instantiate()
	menu_principal.add_sibling(current_special_menu)
	# main_container.add_child(current_special_menu)
	current_special_menu.global_position = pos
	bouton_retour.visible = true

func _on_retour_pressed() -> void:
	# var pos = current_special_menu.global_position
	main_container.remove_child(current_special_menu)
	# main_container.add_child(main_menu)
	# main_menu.global_position = pos
	menu_principal.visible = true
	menu_principal.process_mode = Node.PROCESS_MODE_INHERIT
	bouton_retour.visible = false
