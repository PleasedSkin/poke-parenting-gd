extends Node2D


@onready var get_pokemon_request := %GetPokemon
@onready var get_pokemon_species_request := %GetPokemonSpecies
@onready var get_pokemon_pic_request := %GetPokemonPic
@onready var get_pokemon_evolution_infos_request := %GetPokemonEvolutionInfos
@onready var texture_rect = %PokeTextureRect as TextureRect
@onready var loading_texture_rect = %LoadingTextureRect
@onready var poke_texture_mask = %PokeTextureMask
@onready var pokemon_name_label = %Name
@onready var pokemon_level_label = %Niveau
@onready var stars_amount_label = %NbEtoiles
@onready var menu_principal = %MenuPrincipal
@onready var main_container = %VBoxContainer
# @onready var bouton_retour = %Retour
var current_special_menu
var default_pokemon_sprite
const default_pokemon_name := "Oeuf"
var evolution_pokemon_number 
var can_evolve := false
var evolution_details
var evolution_infos_dict = {} # dico clé niveau d'évol et valeur num pokémon d'évol
var current_pokemon_name: String

var pokemon_number: int
var level: int:
	get:
		return level
	set(value):
		level = value
		_update_level_ui_data()
var stars_amount: int:
	get:
		return stars_amount
	set(value):
		stars_amount = value
		_update_stars_amount_ui_data()

var is_evolving := false
var is_shiny := false


const POKE_API_URL := "https://pokeapi.co/api/v2/"
const DEFAULT_SAVE_FILE = "user://savegamepp.save"


var rng = RandomNumberGenerator.new()

var main_menu


func _ready() -> void:
	main_menu = preload("res://ui/menu_principal.tscn").instantiate()
	default_pokemon_sprite = preload("res://assets/pokemon-egg.png")
	get_pokemon_request.request_completed.connect(_on_pokemon_request_completed)
	get_pokemon_species_request.request_completed.connect(_on_pokemon_species_request_completed)
	get_pokemon_pic_request.request_completed.connect(_on_pokemon_pic_request_completed)
	get_pokemon_evolution_infos_request.request_completed.connect(_on_pokemon_evolution_infos_request_completed)
	PokeParentingEvents.points_emitted.connect(_on_poke_parenting_events_points_emitted)
	PokeParentingEvents.main_item_selected.connect(_on_poke_parenting_events_main_item_selected)
	PokeParentingEvents.return_item_selected.connect(_on_retour_pressed)

	if PokeParentingEvents.load_required:
		_load_game()


func _reset_data() -> void:
	print("RESET")
	level = 0
	stars_amount = 0
	_reset_pokemon()


func _set_loading_mode(toggle: bool) -> void:
	var loading_text = '?'

	if is_evolving:
		poke_texture_mask.set_visible(toggle)
		loading_text = 'Il évolue !'
	else:
		texture_rect.set_visible(!toggle)
		loading_texture_rect.set_visible(toggle)

	if toggle:
		_change_pokemon_label(loading_text)
	else:
		is_evolving = false


func _generate_random_pokemon() -> void:
	pokemon_number = rng.randi_range(1, 1025)
	_generate_targeted_pokemon(pokemon_number)


func _generate_targeted_pokemon(pokemon_id: int, from_loading = false) -> void:
	_set_loading_mode(true)
	evolution_infos_dict = {}
	if !is_evolving && !from_loading:
		is_shiny = false

	get_pokemon_request.request(POKE_API_URL + "pokemon/" + str(pokemon_id))
	get_pokemon_species_request.request(POKE_API_URL + "pokemon-species/" + str(pokemon_id))

func _on_pokemon_request_completed(_result, response_code, _headers, body):
	if response_code == HTTPClient.RESPONSE_OK:
		var pokemon = JSON.parse_string(body.get_string_from_utf8())
		# print(pokemon["name"])
		if !is_evolving:
			var shiny_luck := rng.randi_range(1, 100) % 100 == 0
			if shiny_luck:
				is_shiny = true
				print_debug("Quelle chance, un shiny !")

		var sprite_field = "front_shiny" if is_shiny else "front_default"
		get_pokemon_pic_request.request(pokemon["sprites"][sprite_field])
	else:
		print_debug("Erreur lors de la récupération du pokémon " + str(pokemon_number))


func _on_pokemon_pic_request_completed(_result, response_code, _headers, body):
	if response_code == HTTPClient.RESPONSE_OK:
		var image = Image.new()
		var resultat_chargement = image.load_png_from_buffer(body)
		if resultat_chargement != OK:
			print_debug("Erreur lors du chargement de l'image du pokémon " + str(pokemon_number))
		else:
			var texture = ImageTexture.create_from_image(image)
			texture.set_size_override(Vector2i(200, 200))
			texture_rect.texture = texture

			#_change_pokemon_label(current_pokemon_name) # pour avoir le nom qui apparaît en même temps que l'image
			_set_loading_mode(false)
	else:
		print_debug("Erreur lors de la récupération de l'image du pokémon " + str(pokemon_number))
	

func _on_pokemon_species_request_completed(_result, response_code, _headers, body):
	if response_code == HTTPClient.RESPONSE_OK:
		var pokemon_species = JSON.parse_string(body.get_string_from_utf8())
		var corresponding_item = pokemon_species["names"].filter(func(pkmName): return pkmName.language.name == "fr")[0]
		current_pokemon_name = corresponding_item.name
		_change_pokemon_label(current_pokemon_name)
		var evolution_chain_url = pokemon_species["evolution_chain"]["url"]
		get_pokemon_evolution_infos_request.request(evolution_chain_url)
	else:
		print_debug("Erreur lors de la récupération des données d'espèce pokémon " + str(pokemon_number))


func _on_pokemon_evolution_infos_request_completed(_result, response_code, _headers, body):
	if response_code == HTTPClient.RESPONSE_OK:
		var evolution_infos = JSON.parse_string(body.get_string_from_utf8())
		var evolves_to = evolution_infos["chain"]["evolves_to"]
		
		if evolves_to.size() == 0:
			evolution_infos_dict = {}

		while evolves_to.size() > 0 && _get_evolution_trigger(evolves_to).size() > 0:
			var min_level_to_evolve = evolution_details[0].min_level
			evolution_infos_dict[min_level_to_evolve] = int(evolves_to[0]["species"]["url"].substr((POKE_API_URL + "pokemon-species/").length(), -1).replace("/", ""))
			evolves_to = evolves_to[0]["evolves_to"]
	else:
		print_debug("Erreur lors de la récupération des infos d'évolution du pokémon " + str(pokemon_number))


func _get_evolution_trigger(evolves_to):
	evolution_details = evolves_to[0]["evolution_details"].filter(func(ed): return ed.trigger.name == "level-up")
	return evolution_details

func _change_pokemon_label(new_label: String):
	pokemon_name_label.text = "[center]" + new_label + "[/center]"


func _on_button_pressed() -> void:
	_generate_random_pokemon()
	
func _on_poke_parenting_events_points_emitted(nb_points: int) -> void:
	var old_level = level
	level += nb_points
	if (old_level == 0 && level > 0):
		_generate_random_pokemon()
		# pokemon_number = 2
		# _generate_targeted_pokemon(pokemon_number)
	elif level == 0:
		_reset_pokemon()
	elif level > 100:
		_reset_pokemon()
		level = 0
		stars_amount += 1
	else:
		var niveaux_evol = evolution_infos_dict.keys()
		var niveau_pertinent = 0
		for niv in niveaux_evol:
			if niv == null:
				niveau_pertinent = 0
			elif level >= niv:
				niveau_pertinent = niv
		print_debug(niveau_pertinent)

		if (niveau_pertinent > 0):
			evolution_pokemon_number = evolution_infos_dict.get(niveau_pertinent)
			if evolution_pokemon_number != pokemon_number && _is_not_in_upper_evolution_tree():
				pokemon_number = evolution_pokemon_number
				is_evolving = true
				_generate_targeted_pokemon(evolution_pokemon_number)


	level = clampi(level, 0, 100) 

	_save_game()
	

	# else:
	# 	#if level > old_level
	# 	pass # vérifier via l'API qu'il existe une évolution pour le pokémon actuel
	# 	# regarder ensuite les conditions d'évol (niveau, pierre, etc.) et ne faire qu'une évol à la fois

	# 	# if level < old_level : faire éventuellement désévoluer

func _update_level_ui_data():
	pokemon_level_label.text = "[center]Niveau : " + str(level) + "[/center]"

func _update_stars_amount_ui_data():
	stars_amount_label.text = "x " + str(stars_amount)


func _is_not_in_upper_evolution_tree() -> bool:
	var result := true
	for evolution_infos_dict_key in evolution_infos_dict.keys():
		if evolution_infos_dict.get(evolution_infos_dict_key) == pokemon_number && level < evolution_infos_dict_key:
			return false

	return result


func _reset_pokemon():
	texture_rect.texture = default_pokemon_sprite
	_change_pokemon_label(default_pokemon_name)

func _on_poke_parenting_events_main_item_selected(name: String):
	var pos = menu_principal.global_position
	# main_container.remove_child(menu_principal)
	menu_principal.visible = false
	menu_principal.process_mode = Node.PROCESS_MODE_DISABLED
	current_special_menu = load("res://ui/menus_categorises/" + name.to_lower() + ".tscn").instantiate()
	menu_principal.add_sibling(current_special_menu)
	# main_container.add_child(current_special_menu)
	current_special_menu.global_position = pos
	# var return_item = load("res://ui/item_retour.tscn").instantiate()
	# current_special_menu.add_item_to_menu(return_item)
	# #bouton_retour.visible = true

func _on_retour_pressed() -> void:
	# var pos = current_special_menu.global_position
	main_container.remove_child(current_special_menu)
	# main_container.add_child(main_menu)
	# main_menu.global_position = pos
	menu_principal.visible = true
	menu_principal.process_mode = Node.PROCESS_MODE_INHERIT
	# bouton_retour.visible = false



func save():
	var save_dict = {
		"pokemon_number": pokemon_number,
		"level": level,
		"stars_amount": stars_amount,
		"is_shiny": is_shiny
	}

	return save_dict

func _save_game() -> void:
	var save_game = FileAccess.open(DEFAULT_SAVE_FILE, FileAccess.WRITE)

	var json_string = JSON.stringify(save())

	save_game.store_line(json_string)


func _load_game():
	print("LOADING")
	if not FileAccess.file_exists(DEFAULT_SAVE_FILE):
		return

	var save_game = FileAccess.open(DEFAULT_SAVE_FILE, FileAccess.READ)
	while save_game.get_position() < save_game.get_length():
		var json_string = save_game.get_line()

		# Creates the helper class to interact with JSON
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object
		var node_data = json.get_data()

		level = node_data["level"]
		stars_amount = node_data["stars_amount"]
		pokemon_number = node_data["pokemon_number"]
		is_shiny = node_data["is_shiny"]
		_on_poke_parenting_events_points_emitted(0)
		_generate_targeted_pokemon(pokemon_number, true)
