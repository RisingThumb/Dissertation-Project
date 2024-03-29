extends Node

enum renderTarget {
	STATUS,
	EQUIPMENT,
	INVENTORY,
	TURNS,
	EFFECTS,
	ROOM_TITLE,
	ACTIONS
}

var items = []

# Get some essential UI nodes
onready var turns = $Control/HBoxContainer/VBoxContainer/Turns/Turns/MarginContainer/VBoxContainer
onready var inventory = $Control/HBoxContainer/VBoxContainer/Inventory/Inventory/MarginContainer/VBoxContainer
onready var status = $Control/HBoxContainer/VBoxContainer/Status/Status/MarginContainer/VBoxContainer
onready var effects = $Control/HBoxContainer/MarginContainer/EffectsAndActions/Effect
onready var actions = $Control/HBoxContainer/MarginContainer/EffectsAndActions/Action
onready var room_title = $Control/MarginContainer/RoomTitle
onready var parent_container = $Control/HBoxContainer
onready var choice1Container = $Control/Choice/VBoxContainer2/HBoxContainer/SpellChoice
onready var choice2Container = $Control/Choice/VBoxContainer2/HBoxContainer/SpellChoice2
onready var choice3Container = $Control/Choice/VBoxContainer2/HBoxContainer/SpellChoice3

var itemButton = preload("res://Util/UI/BarComponent.tscn")
var effect = preload("res://Util/UI/EffectComponent.tscn")
var action = preload("res://Util/UI/ActionComponent.tscn")

var turnPrefix = "Remaining:"
var elapsedPrefix = "Elapsed:"
var hpPrefix = "HP:"
var staminaPrefix = "STAMINA:"
var sanityPrefix = "SANITY:"#
var keyPrefix = "Keys:"
var currently_selected = -1

func _ready():
	$Control/Choice.visible = false
	GameState.render = self
	# Redraw all
	for i in renderTarget.values():
		redraw(i)

func redraw(target: int) -> void:
	if target == renderTarget.TURNS:
		var turnsText = numToI(GameState.get_turns_remaining())
		turns.get_node("Turns").text = turnPrefix + turnsText
		turns.get_node("Elapsed").text = elapsedPrefix + str(GameState.get_elapsed())

	if target == renderTarget.STATUS:
		status.get_node("HP").text = hpPrefix + numToI(PlayerState.get_hp())
		status.get_node("Sanity").text = sanityPrefix + numToI(PlayerState.get_sanity())
		turns.get_node("Keys").text = keyPrefix + str(PlayerState.get_keys())

	if target == renderTarget.INVENTORY:
		var children = inventory.get_child_count()
		# Delete all children
		for i in range(1, children):
			inventory.get_child(i).queue_free()
		# Generate all buttons and add them
		for i in range(PlayerState.inventory.size()):
			var newItem = itemButton.instance()
			newItem.set_item_id(PlayerState.inventory[i])
			newItem.text = Item.get_name_by_id(PlayerState.inventory[i])
			inventory.add_child(newItem)
	
	if target == renderTarget.EFFECTS:
		dump_vbox(effects)
		for i in range(PlayerState.status_effects.size()):
			if PlayerState.status_effects[i] != 0:
				var newEffect = effect.instance()
				newEffect.text = PlayerState.get_effect_name(i)
				effects.add_child(newEffect)

	if target == renderTarget.ROOM_TITLE:
		room_title.text = Level.get_current_level().get("name")
		room_title.modulate = Color(Level.get_current_level().get("textfg"))
		parent_container.modulate = Color(Level.get_current_level().get("textfg"))
	
	if target == renderTarget.ACTIONS:
		redraw_actions()

func dump_vbox(vbox: VBoxContainer)->void:
	var children = vbox.get_child_count()
	for i in range(children):
		vbox.get_child(i).queue_free()

func draw_actions(itemId: int) -> void:
	currently_selected = itemId
	redraw_actions()

func present_choices(visible: bool):
	$Control/Choice.visible = visible
	$Control/MarginContainer.visible = !visible
	$Control/ViewportContainer.visible = !visible
	$Control/HBoxContainer.visible = !visible
	get_tree().paused = visible
	if visible:
		set_choices()

func set_choices():
	items = Item.get_spells()
	items.shuffle()
	var choices = [choice1Container, choice2Container, choice3Container]
	for i in range(3):
		if items.size() < i+1:
			break
		var item = items[i]
		choices[i].get_node("MarginContainer/VBoxContainer/SpellName").text = item["name"]
		choices[i].get_node("MarginContainer/VBoxContainer/SpellDesc").text = item["desc"]

func redraw_actions() -> void:
	dump_vbox(actions)
	var functions = Item.get_functions_by_id(currently_selected)
	var extra_functions: Array = GameState.get_extra_actions()
	for function in functions:
		var newAction = action.instance()
		newAction.text = function["name"]
		newAction.set_function(function["function"], function["parameters"])
		actions.add_child(newAction)
	for function in extra_functions:
		var newAction = action.instance()
		newAction.text = function["name"]
		newAction.set_function(function["function"], function["parameters"])
		actions.add_child(newAction)

func numToI(number: int) -> String:
	var text = ""
	for _i in range(number):
		text+="I"
	return text

# Destructor
func _notification(notification):
	if notification == NOTIFICATION_PREDELETE:
		GameState.render = null


func _on_SpellChoice1_pressed():
	present_choices(false)
	PlayerState.inventory.append(Item.get_item_by_name(items[0]["name"]))
	GameState.request_render(renderTarget.INVENTORY)


func _on_SpellChoice2_pressed():
	present_choices(false)
	PlayerState.inventory.append(Item.get_item_by_name(items[1]["name"]))
	GameState.request_render(renderTarget.INVENTORY)


func _on_SpellChoice3_pressed():
	present_choices(false)
	PlayerState.inventory.append(Item.get_item_by_name(items[2]["name"]))
	GameState.request_render(renderTarget.INVENTORY)
