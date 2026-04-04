# 🛠️ Guide du contributeur — testJeu2D

> Godot 4.6 / GDScript — RPG 2D top-down
> Ce document explique comment ajouter ou modifier du contenu de jeu sans toucher à l'architecture centrale.

---

## Sommaire

1. [Ajouter un item (avec icône)](#1-ajouter-un-item-avec-icône)
2. [Ajouter une ressource récoltable](#2-ajouter-une-ressource-récoltable)
3. [Ajouter un animal](#3-ajouter-un-animal)
4. [Ajouter un ennemi](#4-ajouter-un-ennemi)
5. [Configurer un boss](#5-configurer-un-boss)
6. [Ajouter un spawn nocturne](#6-ajouter-un-spawn-nocturne)
7. [Ajouter une recette de craft](#7-ajouter-une-recette-de-craft)
8. [Ajouter une quête](#8-ajouter-une-quête)
9. [Ajouter un PNJ marchand](#9-ajouter-un-pnj-marchand)
10. [Ajouter un talent passif](#10-ajouter-un-talent-passif)
11. [Ajouter un équipement](#11-ajouter-un-équipement)

---

## 1. Ajouter un item (avec icône)

**Fichier :** `scripts/item_data.gd`

Toutes les icônes d'items transitent par cet autoload. Il cherche dans 4 sources dans l'ordre :

| Source | Constante | Usage |
|---|---|---|
| PNG dédié | `_IMAGES` | Item avec sprite custom |
| `rpgItems.png` (8×8 cellules 16px) | `_REG_RPG` | Armes, outils, consommables |
| `itemset0.png` (16×11 cellules 16px) | `_REG_SET0` | Armures, boucliers, potions |
| `spr_tileset_sunnysideworld_16px.png` | `_REG_WORLD` | Plantes, minerais |

### Cas 1 — PNG dédié (fichier unique)

```gdscript
# Dans _IMAGES :
"Cle de donjon": "res://assets/sprites/cle_donjon.png",
```

Placez votre PNG dans `assets/sprites/` et référencez son chemin.

### Cas 2 — Sprite dans un spritesheet existant

Ouvrez le spritesheet dans un éditeur d'image, repérez les coordonnées `x, y` du coin haut-gauche de la cellule et sa taille (toujours 16×16 px), puis ajoutez dans le dictionnaire correspondant :

```gdscript
# Exemple dans _REG_RPG (rpgItems.png) :
"Cle de donjon": Rect2(32, 48, 16, 16),  # x=32, y=48, w=16, h=16

# Exemple dans _REG_SET0 (itemset0.png) :
"Gemme magique": Rect2(64, 32, 16, 16),
```

Une fois l'entrée ajoutée, `ItemData.get_texture("Cle de donjon")` fonctionne automatiquement partout dans le jeu (inventaire, HUD, boutique, crafting).

---

## 2. Ajouter une ressource récoltable

**Fichier :** `scripts/resource_spawner.gd`

### Plante (spawn sur herbe)

Ajoutez une entrée dans `PLANT_DEFS` :

```gdscript
const PLANT_DEFS = [
    {"name": "Plante",     "qty": 1, "health": 1, "tool": ""},
    {"name": "Tournesol",  "qty": 1, "health": 1, "tool": ""},
    # ↓ Votre nouvelle plante
    {"name": "Lavande",    "qty": 2, "health": 1, "tool": ""},
]
```

- `name` : nom exact tel qu'il apparaîtra dans l'inventaire (doit correspondre à `ItemData`)
- `qty` : quantité donnée à la récolte (doublée si le talent `double_loot` est actif)
- `health` : nombre de coups avant récolte
- `tool` : `""` = aucun outil, `"hache"`, `"pioche"`

Le maximum simultané pour les plantes est contrôlé par la constante `MAX_PLANTS` (défaut : 5).

### Minerai (spawn sur chemin/sable)

Ajoutez une entrée dans `MINERAL_DEFS` et les sprites dans `MINERAL_MAP_SPRITES` :

```gdscript
const MINERAL_DEFS = [
    # ...existants...
    {"name": "Obsidienne", "qty": 1, "health": 15, "tool": "pioche", "max": 1},
]

const MINERAL_MAP_SPRITES = {
    # ...existants...
    # 3 variantes visuelles de rocher dans le tileset (x=784/816/848, y selon la ligne)
    "Obsidienne": [Rect2(784, 496, 32, 32), Rect2(816, 496, 32, 32), Rect2(848, 496, 32, 32)],
}
```

- `max` : nombre maximum simultané sur la carte
- Les coordonnées `Rect2` sont dans `spr_tileset_sunnysideworld_16px.png`

N'oubliez pas d'ajouter l'icône inventaire dans `item_data.gd` (voir section 1).

---

## 3. Ajouter un type d'arbre

**Fichier :** `scripts/resource_spawner.gd` — constante `TREE_DEFS`

Si vous avez une nouvelle scène d'arbre (ex. `fruit_tree.tscn`), ajoutez-la dans `TREE_DEFS` :

```gdscript
const TREE_DEFS: Array = [
    # ...existants...
    {
        "scene":     "res://scenes/fruit_tree.tscn",
        "weight":    1,   # fréquence relative — augmentez pour qu'il apparaisse plus souvent
        "overrides": {
            "resource_name": "Pomme",
            "quantity":      1,
            "respawn_time":  120.0,
            "required_tool": "",   # "" = sans outil, "hache" = avec hache
        }
    },
]
```

Pour ajuster la **quantité totale** d'arbres et la **distance minimale** :

```gdscript
const TREE_COUNT:    int   = 30     # nombre d'arbres sur la carte (placement aléatoire)
const TREE_MIN_DIST: float = 48.0   # distance min entre deux arbres (pixels)
```

> Les arbres sont placés aléatoirement à chaque lancement — pas de graine fixe.

---

## 4. Configurer les coffres respawnables

**Fichier :** `scripts/resource_spawner.gd`

Les coffres sont gérés directement par `ResourceSpawner`. Il n'y a pas de liste de coffres à remplir manuellement — leur récompense est tirée aléatoirement à chaque apparition.

### Modifier la table de récompenses

```gdscript
const CHEST_REWARDS: Array = [
    # { contenu, quantite, gold_amount, weight }
    {"contenu": "Potion",         "quantite": 1, "gold_amount": 0,  "weight": 35},
    {"contenu": "or",             "quantite": 0, "gold_amount": 15, "weight": 25},
    # ↓ Ajouter une nouvelle récompense :
    {"contenu": "Cle de donjon",  "quantite": 1, "gold_amount": 0,  "weight": 5},
]
```

- `contenu` : nom de l'item (doit exister dans `ItemData`) ou `"or"` pour de l'or
- `quantite` : nombre d'items (ignoré si `contenu == "or"`)
- `gold_amount` : montant d'or (utilisé uniquement si `contenu == "or"`)
- `weight` : poids relatif — plus il est élevé, plus la récompense est fréquente

### Paramètres généraux des coffres

```gdscript
const MAX_CHESTS:           int   = 5      # coffres max simultanément sur la carte
const CHEST_RESPAWN_DELAY:  float = 600.0  # secondes avant réapparition (défaut : 10 min)
const CHEST_MIN_DIST:       float = 96.0   # distance min entre deux coffres (pixels)
```

---

## 5. Ajouter un animal

**Étape 1 — Créer la scène**

Dupliquez `scenes/mouton.tscn` dans Godot, renommez-la (ex. `cerf.tscn`), et adaptez le sprite et les exports dans l'inspecteur (`animal_name`, `drops`, `max_health`).

**Étape 2 — Enregistrer dans le spawner**

**Fichier :** `scripts/animal_spawner.gd`

```gdscript
const ANIMAL_DEFS = [
    # ...existants...
    {
        "name":      "Cerf",
        "scene":     "res://scenes/cerf.tscn",
        "max":       4,
        "overrides": {
            "max_health": 5,   # PV (défaut animal.gd = 2)
        }
    },
]
```

- `overrides` : toute propriété exportée de `animal.gd` peut être écrasée ici
- `max` : nombre maximum simultané sur la carte (respawn après 120 s)

---

## 6. Ajouter un ennemi

**Étape 1 — Créer la scène dans Godot**

Dupliquez une scène existante (ex. `scenes/skeleton.tscn`), renommez-la, et configurez dans l'inspecteur :

| Export | Rôle |
|---|---|
| `max_health` | Points de vie |
| `speed` | Vitesse de déplacement |
| `damage_per_second` | Dégâts infligés au joueur par attaque |
| `xp_reward` | XP donné à la mort |
| `detection_range` | Rayon (px) de détection du joueur — déclenche la poursuite |
| `attack_range` | Distance (px) à laquelle l'ennemi **s'arrête** et attaque — défaut 38 px. Doit être < `detection_range`. |
| `patrol_range` | Rayon de patrouille autour du point de spawn — défaut 50 px |
| `respawn_time` | Délai (s) avant réapparition après la mort — défaut 5 s |
| `health_bar_offset_y` | Décalage vertical (px) de la barre de vie flottante — défaut −24 |
| `enemy_type` | Identifiant pour les quêtes kill (ex. `"zombie"`) |

**Étape 2 — Ajouter au groupe `enemy`**

Dans Godot, sélectionnez le nœud racine de votre scène → onglet **Node** → **Groups** → ajouter `enemy`. Cela est nécessaire pour que la minimap affiche l'ennemi et que les projectiles le détectent.

**Étape 3 — Vérifier les animations**

`enemy.gd` cherche les animations : `idle_down`, `walk_right`, `walk_down`, `walk_up`, `attack`, `hurt`, `die`. Si votre sprite n'a pas certaines de ces animations, elles sont ignorées silencieusement. `walk_right` est réutilisé à gauche via `flip_h`.

---

## 7. Configurer un boss

Un boss est un ennemi normal avec des exports supplémentaires activés. Tout se fait dans **l'inspecteur Godot** — pas de code à écrire.

Ouvrez la scène de l'ennemi (ex. `golem.tscn`), sélectionnez le nœud racine, et dans l'inspecteur :

| Champ | Valeur exemple | Effet |
|---|---|---|
| `is_boss` | `true` | Active la barre de vie dédiée en bas d'écran |
| `boss_name` | `"Golem de Pierre"` | Nom affiché dans la barre |
| `unique_drops` | voir ci-dessous | Items donnés à la mort |

**Format de `unique_drops`** (tableau de dictionnaires) :

```
[
  { "name": "Cle de donjon", "qty": 1 },
  { "name": "Minerai d'or",  "qty": 3 }
]
```

À la mort du boss : les drops sont ajoutés à l'inventaire, la barre disparaît avec une animation. Le boss ne réapparaît pas (ou avec un délai très long si `respawn_time` est défini).

> **Note :** Ajoutez l'icône de chaque drop dans `item_data.gd` si elle n'existe pas encore (voir section 1).

---

## 8. Ajouter un spawn diurne ou nocturne

Les deux spawners fonctionnent de façon identique. Le spawn diurne (`day_enemy_spawner.gd`) se déclenche à l'aube et disparaît à la nuit. Le spawn nocturne (`night_enemy_spawner.gd`) fait l'inverse.

### Spawn diurne — `scripts/day_enemy_spawner.gd`

Ajoutez une entrée dans `DAY_ENEMY_DEFS` :

```gdscript
const DAY_ENEMY_DEFS: Array = [
    # ...existants...
    {
        "scene":     "res://scenes/goblin.tscn",
        "max":       5,
        "overrides": {
            "speed":             70.0,
            "max_health":        30,
            "damage_per_second": 8.0,
            "xp_reward":         12,
        }
    },
]
```

### Spawn nocturne — `scripts/night_enemy_spawner.gd`

Ajoutez une entrée dans `NIGHT_ENEMY_DEFS` :

```gdscript
const NIGHT_ENEMY_DEFS: Array = [
    # ...existants...
    {
        "scene":     "res://scenes/zombie.tscn",
        "max":       4,
        "overrides": {
            "speed":             40.0,
            "max_health":        80,
            "damage_per_second": 8.0,
            "xp_reward":         30,
        }
    },
]
```

- Les ennemis apparaissent en fondu à la tombée de la nuit et disparaissent à l'aube
- `overrides` est optionnel : sans lui, les valeurs exportées de la scène sont utilisées telles quelles
- La distance minimale entre spawns et la distance de sécurité joueur sont contrôlées par `MIN_DIST` et `PLAYER_SAFE_DIST`

La scène doit exister et son nœud racine doit être dans le groupe `enemy`.

---

## 9. Ajouter une recette de craft

**Fichier :** `scripts/crafting_panel.gd` — dictionnaire `RECIPES`

Il y a trois onglets : `"armes"`, `"potions"`, `"cuir"`. Ajoutez votre recette dans le bon tableau :

```gdscript
# Recette toujours disponible
{
    "name":        "Torche",
    "ingredients": {"Bois": 1, "Charbon": 1},
    "result":      "Torche",
    "result_qty":  3,
},

# Recette débloquée par un livre
{
    "name":        "Arc en fer",
    "ingredients": {"Minerai de fer": 2, "Bois": 2},
    "result":      "Arc en fer",
    "result_qty":  1,
    "book":        "Livre du forgeron",
},
```

- `"book"` est optionnel — sans ce champ, la recette est disponible dès le départ
- Le `result` doit avoir une icône dans `item_data.gd`
- Pour ajouter un nouvel onglet, cherchez `tab_bar.add_tab(` dans `crafting_panel.gd`

---

## 10. Ajouter une quête

**Fichier :** `scripts/quest_manager.gd` — dictionnaire `QUESTS`

```gdscript
var QUESTS = {
    # ...existantes...
    "ma_nouvelle_quete": {
        "id":           "ma_nouvelle_quete",
        "name":         "Chasseur de golems",
        "description":  "Tuer 3 golems",
        "type":         "kill",       # "kill" ou "collect"
        "target":       "golem",      # enemy_type pour "kill", resource_name pour "collect"
        "required":     3,
        "progress":     0,
        "reward_xp":    120,
        "reward_gold":  80,
        "reward_items": { "Grande potion": 1 },
        "completed":    false,
        "reward_claimed": false
    }
}
```

**Types de quête disponibles :**
- `"kill"` : progressée par `QuestManager.update_kill(enemy_type)` — appelé automatiquement dans `enemy.gd`
- `"collect"` : progressée par `QuestManager.update_collect(resource_name)` — appelé automatiquement dans `resource.gd`

**Lier la quête à un PNJ :** dans le script du PNJ (ex. `NPCbucheron.gd`), définissez `quest_id = "ma_nouvelle_quete"`. L'icône de quête au-dessus du PNJ et les dialogues contextuels se gèrent automatiquement.

---

## 11. Ajouter un PNJ marchand

**Étape 1 — Créer la scène**

Dupliquez `scenes/npc.tscn`, attachez-lui le script `scripts/npc_merchant.gd`.

**Étape 2 — Configurer dans l'inspecteur**

| Export | Description |
|---|---|
| `merchant_name` | Nom affiché dans les dialogues |
| `shop_title` | Titre de la fenêtre boutique |
| `sell_items` | Articles vendus (tableau de `{name, price}`) |
| `can_buy_from_player` | Le marchand rachète les items du joueur |
| `buy_prices` | Prix de rachat par item (`{"Bois": 3, …}`) |

**Format de `sell_items` :**

```
[
  { "name": "Potion",      "price": 30  },
  { "name": "Epee en fer", "price": 200 },
  { "name": "Torche",      "price": 10  }
]
```

Les noms doivent correspondre exactement à ceux de l'inventaire. Les icônes sont récupérées automatiquement via `ItemData`.

---

## 12. Ajouter un talent passif

**Fichier :** `scripts/stats.gd` — constante `TALENT_POOL`

### Déclarer le talent

```gdscript
const TALENT_POOL = [
    # ...existants...
    { "id": "fire_arrows", "label": "Flèches de feu", "desc": "Les flèches brûlent les ennemis (dégâts sur 2s)" },
]
```

- `id` : identifiant interne (snake_case, unique)
- `label` : nom affiché sur la carte de sélection
- `desc` : description courte de l'effet

### Brancher l'effet

L'effet doit être vérifié **au moment où il s'applique**, avec `Stats.has_talent("fire_arrows")`. Il n'y a pas de système d'événement central — chaque script concerné fait sa propre vérification.

Exemples selon le type d'effet :

**Effet sur une stat** → modifier la fonction `get_*` dans `stats.gd` :
```gdscript
func get_damage() -> int:
    var bonus = 5 if has_talent("fire_arrows") else 0
    return 10 + (get_force() * 2) + bonus
```

**Effet lors d'une action** → ajouter un `if` dans le script concerné :
```gdscript
# Dans projectile.gd — _check_hit()
if Stats.has_talent("fire_arrows"):
    body.apply_status("burn", 2.0)  # exemple d'appel

# Dans player.gd — _dodge()
if Stats.has_talent("dash_heal"):
    heal(3)

# Dans enemy.gd — die()
if Stats.has_talent("regen_on_kill"):
    player.heal(5)
```

Le talent est proposé tous les **3 niveaux**, parmi ceux non encore acquis. Il est sauvegardé automatiquement dans `GameManager`.

### Ajouter l'icône HUD du nouveau talent

Chaque talent actif est représenté visuellement dans le HUD par un petit carré coloré. Quand vous ajoutez un talent dans `TALENT_POOL`, ajoutez également une entrée dans `TALENT_ICON_DEFS` (en haut de `scripts/hud.gd`) :

```gdscript
const TALENT_ICON_DEFS: Dictionary = {
    # ...existants...
    "fire_arrows": {
        "abbr":  "FE",                        # 2 lettres affichées dans le carré
        "color": Color("#e74c3c"),             # couleur de fond distinctive
        "full":  "Flèches de feu — brûlent les ennemis"   # texte du tooltip
    },
}
```

Choisissez une couleur non encore utilisée pour que les talents restent distinguables d'un coup d'œil.

---

## 13. Ajouter un équipement

**Fichier :** `scripts/stats.gd` — dictionnaire `equipment_data`

```gdscript
var equipment_data = {
    # ...existants...
    "Epee de cristal": {
        "slot":        "arme",    # "arme", "casque", "plastron", "bottes", "bouclier", "anneau", "amulette"
        "force":       12,
        "endurance":   0,
        "agilite":     2,
        "magie":       5,
        "defense":     0,
        "description": "Lame taillée dans le cristal pur"
    },
}
```

Ajoutez ensuite l'icône dans `item_data.gd` (section 1). L'item peut alors être placé dans un coffre, droppé par un boss, ou vendu par un marchand — il sera équipable automatiquement depuis l'inventaire **et apparaîtra dans le panneau d'équipement visuel (G)** dès qu'il est dans l'inventaire du joueur.

---

## Récapitulatif des fichiers à modifier selon la tâche

| Ce que vous voulez ajouter | Fichier(s) à modifier |
|---|---|
| Icône d'item | `scripts/item_data.gd` |
| Nouvelle plante | `scripts/resource_spawner.gd` + `item_data.gd` |
| Nouveau minerai | `scripts/resource_spawner.gd` + `item_data.gd` |
| Nouvel animal | `scripts/animal_spawner.gd` + scène Godot |
| Nouvel ennemi | Scène Godot uniquement (groupe `enemy` requis) |
| Boss | Inspecteur Godot uniquement (`is_boss`, `unique_drops`) |
| Spawn diurne | `scripts/day_enemy_spawner.gd` |
| Spawn nocturne | `scripts/night_enemy_spawner.gd` |
| Nouvel arbre | `scripts/resource_spawner.gd` (`TREE_DEFS`) |
| Récompenses coffres | `scripts/resource_spawner.gd` (`CHEST_REWARDS`) |
| Recette de craft | `scripts/crafting_panel.gd` |
| Quête | `scripts/quest_manager.gd` + script PNJ |
| PNJ marchand | Scène Godot + inspecteur |
| Talent passif | `scripts/stats.gd` + script(s) concerné(s) + `hud.gd` (`TALENT_ICON_DEFS`) |
| Équipement | `scripts/stats.gd` + `item_data.gd` (apparaît automatiquement dans le panneau G) |
