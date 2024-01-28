extends MenuItem


@export var comportement: ComportementResource

func cursor_select():
	super.cursor_select()
	PokeParentingEvents.emit_signal("points_emitted", comportement.points)
