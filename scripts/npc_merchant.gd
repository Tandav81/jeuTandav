extends "res://scripts/npc.gd"
# ============================================================
#  NPCMarchand — PNJ marchand totalement paramétrable
#
#  🔧 CONFIGURER LA BOUTIQUE :
#  Dans l'inspecteur Godot, modifie les exports :
#    - merchant_name  : nom du marchand affiché
#    - shop_title     : titre de la fenêtre boutique
#    - sell_items     : liste des articles à vendre
#    - buy_multiplier : coefficient sur le prix de vente au joueur
#                       (ex. 1.5 = le marchand vend 50% plus cher)
#
#  🔧 AJOUTER UN ARTICLE (en GDScript, dans un script enfant) :
#  sell_items = [
#      { "name": "Potion",    "price": 30 },
#      { "name": "Epee en fer", "price": 150 },
#      { "name": "Bois",      "price": 5  },
#  ]
#  → "name"  doit correspondre exactement au nom dans l'inventaire
#  → "price" = prix en or pour acheter cet article au marchand
#
#  🔧 ACTIVER L'ACHAT (le marchand rachète les items du joueur) :
#  Mettre can_buy_from_player = true et définir buy_prices :
#  buy_prices = { "Bois": 3, "Pierre brute": 2, "Plante": 8 }
#  (Si un item n'est pas dans buy_prices, le marchand utilise
#   price / 2 par défaut.)
# ============================================================

## Nom affiché dans le dialogue d'accueil
@export var merchant_name: String = "Marchand"
## Titre de la fenêtre boutique
@export var shop_title: String = "Boutique"

## Articles vendus par le marchand
## Format : [ { "name": "Potion", "price": 30 }, … ]
@export var sell_items: Array = [
	{ "name": "Potion",        "price": 30  },
	{ "name": "Epee en bois",  "price": 50  },
	{ "name": "Epee en fer",   "price": 200 },
]

## Le marchand rachète-t-il des items au joueur ?
@export var can_buy_from_player: bool = true

## Prix de rachat par item (optionnel — défaut = price/2)
## Format : { "Bois": 3, "Pierre brute": 2 }
@export var buy_prices: Dictionary = {
	"Bois":         3,
	"Pierre brute": 2,
	"Plante":       8,
	"Champignon":   6,
	"Baie":         5,
	"Charbon":      12,
	"Minerai de fer": 20,
	"Cristal":      45,
	"Minerai d'or": 60,
}

# ============================================================
func _ready() -> void:
	npc_name = merchant_name

	# Dialogues contextuels du marchand
	dialogue_data["default"] = [
		"Bonjour, " + merchant_name + " pour vous servir !",
		{ "text": "Que puis-je faire pour vous ?",
		  "choices": [
			{ "label": "Voir la boutique", "goto": "open_shop" },
			{ "label": "Au revoir",        "goto": "bye"        },
		  ]
		},
	]
	dialogue_data["open_shop"] = [
		{ "action": "open_shop" },
	]
	dialogue_data["bye"] = [
		"Bonne route, ami adventurier !",
	]

	# Pas de quête sur ce PNJ
	quest_id = ""
	super._ready()

# ============================================================
#  SURCHARGE DE L'ACTION — ouvrir la boutique
# ============================================================

func _execute_action(action: String) -> void:
	if action == "open_shop":
		_end_dialogue()
		var hud = _get_hud()
		if hud:
			hud.open_shop(self)
	else:
		super._execute_action(action)
