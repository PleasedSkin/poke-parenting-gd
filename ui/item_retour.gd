extends MenuItem


func cursor_select():
	PokeParentingEvents.return_item_selected.emit()
