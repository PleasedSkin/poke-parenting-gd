extends Node2D


@onready var get_pokemon_request := %GetPokemon
@onready var get_pokemon_species_request := %GetPokemonSpecies
@onready var get_pokemon_pic_request := %GetPokemonPic
@onready var get_pokemon_evolution_infos_request := %GetPokemonEvolutionInfos
@onready var texture_rect = %PokeTextureRect as TextureRect
@onready var pokemon_name_label = %Name
@onready var pokemon_level_label = %Niveau
@onready var stars_amount_label = %NbEtoiles
@onready var menu_principal = %MenuPrincipal
@onready var main_container = %VBoxContainer
@onready var bouton_retour = %Retour
var current_special_menu
var default_pokemon_sprite
const default_pokemon_name := "Oeuf"
var evolution_pokemon_number 
var can_evolve := false
var evolution_details
var evolution_infos_dict = {} # dico clé niveau d'évol et valeur num pokémon d'évol
var current_pokemon_name: String

var level := 0
var stars_amount := 0


const POKE_API_URL := "https://pokeapi.co/api/v2/"

var pokemon_number: int

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
	PokeParentingEvents.reset_required.connect(reset_data)
	#_generate_random_pokemon()


func reset_data() -> void:
	level = 0
	stars_amount = 0
	_reset_pokemon()


func _generate_random_pokemon() -> void:
	pokemon_number = rng.randi_range(1, 1025)
	_generate_targeted_pokemon(pokemon_number)


func _generate_targeted_pokemon(pokemon_id: int) -> void:
	get_pokemon_request.request(POKE_API_URL + "pokemon/" + str(pokemon_id))
	get_pokemon_species_request.request(POKE_API_URL + "pokemon-species/" + str(pokemon_id))

func _on_pokemon_request_completed(_result, response_code, _headers, body):
	if response_code == HTTPClient.RESPONSE_OK:
		var pokemon = JSON.parse_string(body.get_string_from_utf8())
		# print(pokemon["name"])
		get_pokemon_pic_request.request(pokemon["sprites"]["front_default"])
	else:
		print_debug("Erreur lors de la récupération du pokémon " + str(pokemon_number))


func _on_pokemon_pic_request_completed(_result, response_code, _headers, body):
	if response_code == HTTPClient.RESPONSE_OK:
		var image = Image.new()
		var resultat_chargement = image.load_png_from_buffer(body)
		_change_pokemon_label(current_pokemon_name) # pour avoir le nom qui apparaît en même temps que l'image
		if resultat_chargement != OK:
			print_debug("Erreur lors du chargement de l'image du pokémon " + str(pokemon_number))
		else:
			var texture = ImageTexture.create_from_image(image)
			texture.set_size_override(Vector2i(200, 200))
			
			texture_rect.texture = texture
	else:
		print_debug("Erreur lors de la récupération de l'image du pokémon " + str(pokemon_number))
	

func _on_pokemon_species_request_completed(_result, response_code, _headers, body):
	if response_code == HTTPClient.RESPONSE_OK:
		var pokemon_species = JSON.parse_string(body.get_string_from_utf8())
		var corresponding_item = pokemon_species["names"].filter(func(pkmName): return pkmName.language.name == "fr")[0]
		# _change_pokemon_label(corresponding_item.name)
		current_pokemon_name = corresponding_item.name
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
		# pokemon_number = 7
		# _generate_targeted_pokemon(pokemon_number)
	elif level == 0:
		_reset_pokemon()
	elif level > 100:
		_reset_pokemon()
		level = 0
		stars_amount += 1
		stars_amount_label.text = "x " + str(stars_amount)
	else:
		var niveaux_evol = evolution_infos_dict.keys()
		var niveau_pertinent = 0
		for niv in niveaux_evol:
			if level >= niv:
				niveau_pertinent = niv
		# print(niveau_pertinent)

		if (niveau_pertinent > 0):
			evolution_pokemon_number = evolution_infos_dict.get(niveau_pertinent)
			if evolution_pokemon_number != pokemon_number:
				pokemon_number = evolution_pokemon_number
				_generate_targeted_pokemon(evolution_pokemon_number)


	level = clampi(level, 0, 100) 
	pokemon_level_label.text = "[center]Niveau : " + str(level) + "[/center]"
	

	# else:
	# 	#if level > old_level
	# 	pass # vérifier via l'API qu'il existe une évolution pour le pokémon actuel
	# 	# regarder ensuite les conditions d'évol (niveau, pierre, etc.) et ne faire qu'une évol à la fois

	# 	# if level < old_level : faire éventuellement désévoluer


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
	bouton_retour.visible = true

func _on_retour_pressed() -> void:
	# var pos = current_special_menu.global_position
	main_container.remove_child(current_special_menu)
	# main_container.add_child(main_menu)
	# main_menu.global_position = pos
	menu_principal.visible = true
	menu_principal.process_mode = Node.PROCESS_MODE_INHERIT
	bouton_retour.visible = false
