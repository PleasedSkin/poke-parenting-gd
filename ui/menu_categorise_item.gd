extends MenuItem


@export var comportement: ComportementResource

func _ready():
	super._ready()
	text = "[center]" + comportement.nom + "[/center]"

func cursor_select():
	PokeParentingEvents.emit_signal("points_emitted", comportement.points)
