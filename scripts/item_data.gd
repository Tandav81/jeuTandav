extends Node
# ============================================================
#  ItemData — autoload global
#  Source unique pour toutes les icônes d'items.
#  Utilisation : ItemData.get_texture("Epee en fer")
# ============================================================

const _TEX_RPG      = "res://assets/rpgItems.png"   # 128×128, cellules 16×16 (8×8)
const _TEX_SET0     = "res://assets/itemset0.png"    # 256×176, cellules 16×16 (16×11)
const _TEX_WORLD    = "res://assets/Tileset/spr_tileset_sunnysideworld_16px.png"  # 1024×1024

# Images PNG dédiées (items sans spritesheet)
const _IMAGES = {
	"Bois": "res://assets/sprites/wood/wood.png",
	"Epee en or":  "res://assets/10swords/goldsword.png",  # grande épée
}

# Régions dans rpgItems.png
const _REG_RPG = {
	# Consommables
	"Viande":         Rect2(16,  64,  16, 16),
	"Cle de donjon":  Rect2(32,  112,  16, 16),
	# Outils
	"Hache":          Rect2(64,  80,  16, 16),
	"Pioche":         Rect2(80,  48,  16, 16),
	# Armes
	"Epee en bois":   Rect2(80,  64,  16, 16),
	"Epee en fer":    Rect2(112, 64,  16, 16),
	"Arc":            Rect2(64,  96,  16, 16),
	"Arc en fer":     Rect2(96,  96,  16, 16),
	# Armures métal
	"Casque en fer":  Rect2(96,  0,   16, 16),  # heaume métal
	"Bottes en fer":  Rect2(112, 16,  16, 16),  # bottes métal
	"Plastron en fer":Rect2(112,  0,  16, 16),
	# Magie
	"Anneau de feu":  Rect2(0,  112,  16, 16),
	"Anneau de glace":Rect2(16,  112,  16, 16),
}

# Régions dans spr_tileset_sunnysideworld_16px.png
# Plantes (ligne y=160) et minerais (gems 16×16 à x=880)
const _REG_WORLD = {
	# ── Plantes récoltables ─────────────────────────────────────
	"Tournesol":       Rect2(864, 160, 16, 16),  # fleur jaune
	"Betterave":       Rect2(880, 160, 16, 16),  # racine rouge
	"Carotte":         Rect2(896, 160, 16, 16),  # carotte orange
	"Pomme de terre":  Rect2(912, 160, 16, 16),  # tubercule brun
	"Oignon":          Rect2(944, 160, 16, 16),  # oignon violet
	"Champignon":      Rect2(1008,160, 16, 16),  # champignon rouge
	"Salade":          Rect2(976, 160, 16, 16),  # feuille verte
	"Baie":            Rect2(992, 160, 16, 16),  # petite baie bleue
	# ── Minerais (icônes gems 16×16) ────────────────────────────
	# Les rochers 2×2 sont à x=864 ; les gems collectables à x=880
	"Pierre brute":    Rect2(880, 480, 16, 16),  # caillou gris clair
	"Minerai de fer":  Rect2(880, 352, 16, 16),  # gem gris argenté
	"Charbon":         Rect2(880, 384, 16, 16),  # gem gris très foncé
	"Cristal":         Rect2(880, 416, 16, 16),  # gem cyan lumineux
	"Minerai d'or":    Rect2(880, 448, 16, 16),  # gem orange doré
}

# Régions dans itemset0.png
const _REG_SET0 = {
	# Consommables
	"Potion":            Rect2(32,   160,   16, 16),  # fiole rouge
	"Grande potion":     Rect2(16,  0,   16, 16),  # fiole jaune (soin ×2)
	"Potion de force":   Rect2(48,  0,   16, 16),  # fiole verte
	"Potion de mana":    Rect2(32,  0,   16, 16),  # fiole bleue
	# Ressources
	"Plante":            Rect2(160, 0,   16, 16),
	"Peau":              Rect2(144, 128, 16, 16),
	# Livres de recettes
	"Livre du forgeron": Rect2(0,   16,  16, 16),
	"Livre du mage":     Rect2(16,  16,  16, 16),
	# Boucliers
	"Bouclier en bois":  Rect2(96,  96,  16, 16),
	"Bouclier en fer":   Rect2(112, 96,  16, 16),
	"Baton magique":  	 Rect2(0,  96,  16, 16),
	"Baton magique feu": Rect2(32,  96,  16, 16),
	"Baton magique glace": Rect2(16,  96,  16, 16),
	# Armures
	"Casque en cuir":    Rect2(112, 112, 16, 16),
	"Bottes légères":    Rect2(96,  48,  16, 16),
}

# ------------------------------------------------------------
#  API publique
# ------------------------------------------------------------

## Retourne la Texture2D pour l'item donné, ou null si inconnu.
func get_texture(item_name: String) -> Texture2D:
	# 1. PNG dédié
	if _IMAGES.has(item_name):
		var path: String = _IMAGES[item_name]
		if ResourceLoader.exists(path):
			return load(path)

	# 2. rpgItems.png
	if _REG_RPG.has(item_name):
		if ResourceLoader.exists(_TEX_RPG):
			var atlas := AtlasTexture.new()
			atlas.atlas  = load(_TEX_RPG)
			atlas.region = _REG_RPG[item_name]
			return atlas

	# 3. itemset0.png
	if _REG_SET0.has(item_name):
		if ResourceLoader.exists(_TEX_SET0):
			var atlas := AtlasTexture.new()
			atlas.atlas  = load(_TEX_SET0)
			atlas.region = _REG_SET0[item_name]
			return atlas

	# 4. spr_tileset_sunnysideworld_16px.png (plantes & minerais)
	if _REG_WORLD.has(item_name):
		if ResourceLoader.exists(_TEX_WORLD):
			var atlas := AtlasTexture.new()
			atlas.atlas  = load(_TEX_WORLD)
			atlas.region = _REG_WORLD[item_name]
			return atlas

	return null

## Retourne true si l'item a une icône connue.
func has_texture(item_name: String) -> bool:
	return _IMAGES.has(item_name) or _REG_RPG.has(item_name) \
		or _REG_SET0.has(item_name) or _REG_WORLD.has(item_name)
