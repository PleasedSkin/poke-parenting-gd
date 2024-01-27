extends Node2D


@onready var get_pokemon_request := %GetPokemon
@onready var get_pokemon_species_request := %GetPokemonSpecies
@onready var get_pokemon_pic_request := %GetPokemonPic
@onready var texture_rect = %TextureRect as TextureRect
@onready var pokemon_name_label = %Name

const POKE_API_URL := "https://pokeapi.co/api/v2/"

var pokemon_number: int

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	get_pokemon_request.request_completed.connect(_on_pokemon_request_completed)
	get_pokemon_species_request.request_completed.connect(_on_pokemon_species_request_completed)
	get_pokemon_pic_request.request_completed.connect(_on_pokemon_pic_request_completed)
	#_generate_random_pokemon()

func _generate_random_pokemon() -> void:
	pokemon_number = rng.randi_range(1, 1025)
	get_pokemon_request.request(POKE_API_URL + "pokemon/" + str(pokemon_number))
	get_pokemon_species_request.request(POKE_API_URL + "pokemon-species/" + str(pokemon_number))

func _on_pokemon_request_completed(result, response_code, headers, body):
	if response_code == HTTPClient.RESPONSE_OK:
		var pokemon = JSON.parse_string(body.get_string_from_utf8())
		#print(pokemon["name"])
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
