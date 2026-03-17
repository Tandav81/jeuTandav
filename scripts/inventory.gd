extends Node

var items = {}
var gold = 0
var equipped_tool = ""

signal inventory_changed

func add_item(item_name: String, quantity: int):
	if items.has(item_name):
		items[item_name] += quantity
	else:
		items[item_name] = quantity
	emit_signal("inventory_changed")

func remove_item(item_name: String, quantity: int) -> bool:
	if not items.has(item_name) or items[item_name] < quantity:
		return false
	items[item_name] -= quantity
	if items[item_name] <= 0:
		items.erase(item_name)
	emit_signal("inventory_changed")
	return true

func has_item(item_name: String, quantity: int = 1) -> bool:
	return items.has(item_name) and items[item_name] >= quantity

func equip_tool(tool_name: String):
	equipped_tool = tool_name
	emit_signal("inventory_changed")

func add_gold(amount: int):
	gold += amount
	emit_signal("inventory_changed")
