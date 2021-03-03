extends Node2D

enum Item {
	MEAT,
	BREAD,
	FRUIT,
	EYES,
	CANDY,
	POTION_MINOR,
	POTION_MAJOR,
	KEY,
}

var hpToGive = 0
var sanityToGive = 0
var keysToGive = 0

var items = {
	Item.KEY : {
		"frames"	: [218, 219],
		"sanity"	: 0,
		"hp"		: 0,
		"keys"		: 1,
	},
	Item.MEAT: {
		"frames" 	: [240, 241, 243],
		"sanity" 	: 0,
		"hp"		: 4,
		"keys"		: 0,
	},
	Item.BREAD: {
		"frames"	: [242, 245, 247],
		"sanity"	: 0,
		"hp"		: 2,
		"keys"		: 0,
	},
	Item.FRUIT: {
		"frames"	: [248, 249, 250, 251],
		"sanity"	: 0,
		"hp"		: 1,
		"keys"		: 0,
	},
	Item.EYES: {
		"frames" 	: [244, 256],
		"sanity"	: 1,
		"hp"		: 0,
		"keys"		: 0,
	},
	Item.CANDY: {
		"frames"	: [254],
		"sanity"	: 1,
		"hp"		: 1,
		"keys"		: 0,
	},
	Item.POTION_MINOR: {
		"frames"	: [259],
		"sanity"	: 2,
		"hp"		: 0,
		"keys"		: 0,
	},
	Item.POTION_MAJOR: {
		"frames"	: [260],
		"sanity"	: 4,
		"hp"		: 0,
		"keys"		: 0,
	}
}

func set_item(item):
	var itemOfInterest = items[item]
	var frames = itemOfInterest["frames"]
	$TextureSprite.frame = frames[randi() % frames.size()]
	hpToGive = itemOfInterest["hp"]
	sanityToGive = itemOfInterest["sanity"]
	keysToGive = itemOfInterest["keys"]


func _on_Area2D_area_entered(area):
	if "Player" in area.get_groups():
		PlayerState.change_hp(hpToGive)
		PlayerState.change_sanity(sanityToGive)
		PlayerState.change_keys(keysToGive)
		GameState.map.EntityContainer.remove_child(self)
		queue_free()
