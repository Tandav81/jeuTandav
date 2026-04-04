# 📋 Récapitulatif du projet — testJeu2D

> Godot 4.6 — Jeu 2D RPG (top-down)
> Dernière mise à jour : 2026-04-04

---

## 🗂️ Structure du projet

```
test-jeu-2d/
├── project.godot
├── scenes/
│   ├── world.tscn                  ← scène principale (extérieur)
│   ├── cave.tscn                   ← scène grotte (accessible via portail)
│   ├── main_menu.tscn              ← menu principal
│   ├── player.tscn                 ← personnage joueur
│   ├── npc.tscn                    ← PNJ base
│   ├── portal.tscn                 ← portail de transition entre scènes
│   ├── chest.tscn                  ← coffre interactif
│   ├── item.tscn                   ← objet ramassable
│   ├── rock.tscn                   ← ressource (minerai statique — legacy)
│   ├── tree.tscn                   ← ressource (bois statique — legacy)
│   ├── slime.tscn                  ← ennemi Slime
│   ├── skeleton.tscn               ← ennemi Squelette
│   ├── golem.tscn                  ← ennemi Golem (boss)
│   ├── bat.tscn                    ← ennemi Chauve-souris (grotte)
│   ├── minotaur.tscn               ← ennemi Minotaure
│   ├── flyingMushroom.tscn         ← ennemi Champignon volant
│   ├── mouton.tscn                 ← animal (mouton)
│   ├── vache.tscn                  ← animal (vache)
│   └── poulet.tscn                 ← animal (poulet)
├── scripts/
│   ├── player.gd
│   ├── enemy.gd                    ← script commun à tous les ennemis
│   ├── npc.gd                      ← base PNJ avec système de dialogue
│   ├── NPCbucheron.gd              ← PNJ spécialisé (extends npc.gd)
│   ├── NPCslime.gd                 ← PNJ spécialisé (extends npc.gd)
│   ├── animal.gd
│   ├── animal_spawner.gd           ← spawn dynamique des animaux
│   ├── resource.gd
│   ├── resource_spawner.gd         ← spawn dynamique des ressources
│   ├── day_night_cycle.gd          ← cycle jour/nuit avec overlay
│   ├── fog_of_war.gd               ← brouillard de guerre par scène
│   ├── portal.gd                   ← portail de transition
│   ├── scene_transition.gd         ← Autoload fondu noir entre scènes
│   ├── chest.gd
│   ├── item.gd
│   ├── item_data.gd                ← Autoload textures des items
│   ├── projectile.gd
│   ├── hud.gd
│   ├── crafting_panel.gd
│   ├── main_menu.gd
│   ├── game_manager.gd             ← Autoload
│   ├── inventory.gd                ← Autoload
│   ├── quest_manager.gd            ← Autoload
│   ├── stats.gd                    ← Autoload
│   ├── night_enemy_spawner.gd      ← spawn dynamique ennemis nocturnes
│   ├── npc_merchant.gd             ← PNJ marchand (extends npc.gd)
│   └── (minimap.gd)                ← ⏳ à créer
└── assets/
	├── Player/                     ← spritesheets joueur (attaque, arc…)
	├── Enemies/                    ← Bat/, Golem_1/, flyingMushroom/, etc.
	├── Animals/                    ← Chicken/, etc.
	├── sprites/                    ← redbar_00 à redbar_06 (barre de vie ennemis)
	├── Tileset/                    ← spr_tileset_sunnysideworld_16px.png
	├── menus/                      ← character_panel.png (HUD barres)
	├── rpgItems.png                ← spritesheet items 16×16
	└── itemset0.png                ← spritesheet items 16×16
```

**Autoloads enregistrés :**
- `GameManager` — sauvegarde, position de spawn, état des coffres, scène courante, temps du jour, données brouillard
- `Inventory` — inventaire, or, outils, équipements
- `QuestManager` — quêtes actives/complètes, progression
- `Stats` — niveau, XP, statistiques, mana, données d'équipements
- `ItemData` — textures des items (sprites depuis les tilesets)
- `SceneTransition` — fondu noir entre les scènes

**Touches configurées :**
| Action | Touche |
|---|---|
| Déplacement | Flèches directionnelles |
| Attaque | Espace |
| Changer d'arme | Q |
| Interagir | E |
| Ouvrir inventaire | I |
| Ouvrir crafting | B |
| Panneau personnage | P |
| Journal de quêtes | C |
| Sauvegarder | S |
| Guide d'aide | F1 |
| Fermer menu | Échap |

---

## ✅ Fonctionnalités implémentées

### 🎮 Joueur
- Déplacement en 4 directions avec animations (marche, idle, attaque, outils)
- Système de vie avec signal `health_changed`
- Dégâts réduits par la défense : `dégâts reçus = max(1, dégâts - Stats.get_defense())`
- Attaque au corps à corps avec zone de collision directionnelle (`AttackZone`)
- **Attaque à distance — Arc** : animation dédiée (6 frames), spawn d'une flèche
- **Attaque à distance — Bâton magique** : consomme de la mana, spawn d'un projectile de sort
- Portée des projectiles calculée selon les stats
- **Changement d'arme** via touche Q : cycle parmi les armes possédées
- Invincibilité pendant l'attaque
- Utilisation d'outils orientés (hache, pioche) avec animations dédiées
- Guérison via potions (+30 PV) et viande (+15 PV)
- Respawn à la position sauvegardée
- `max_health` synchronisé avec `Stats.get_max_health()` au démarrage

### 🏹 Projectiles
- Script `projectile.gd` commun pour flèche et sort
- Propriétés configurables : `proj_type`, `direction`, `max_range`, `damage`
- Déplacement en ligne droite, disparition au-delà de la portée max
- Détection de collision via `PhysicsShapeQueryParameters2D`

### 🗺️ Monde & Navigation
- TileMapLayer avec 3 types de terrain : Herbe, Chemin (sable), Ferme
- **Portails de transition** (`portal.gd` + `SceneTransition`) : fondu noir 0.5 s → changement de scène → fondu retour
- **Scène Grotte** (`cave.tscn`) : environnement séparé avec ennemis dédiés (Chauve-souris) et portail de retour
- Position de spawn configurable par portail
- Sauvegarde du brouillard par scène dans `GameManager.fog_data`

### 🌅 Cycle Jour/Nuit
- Overlay `ColorRect` sur `CanvasLayer` avec interpolation de couleur
- Durée d'un cycle : **20 minutes** réelles (1200 secondes)
- Plages horaires : Aube (6h–9h), Plein jour (9h–15h), Crépuscule (16h48–18h), Nuit (18h–6h)
- Nuits jouables (alpha 0.55 — assombri sans être noir complet)
- Horloge en temps réel affichée sur le HUD (format HH:MM)
- Signal `time_of_day_changed` (valeurs: `"day"`, `"night"`, `"dawn"`, `"dusk"`)
- L'heure courante est sauvegardée et restaurée via `GameManager`

### 🌫️ Brouillard de Guerre
- Image pixel : 1 pixel = 1 tuile, mise à jour en temps réel via `ImageTexture`
- Révélation progressive avec fondu sur les bords (rayon 7 tuiles)
- Persiste par scène : rechargé au retour depuis la grotte
- Sauvegarde/chargement des cellules révélées

### 👾 Ennemis
- Script commun `enemy.gd` — instancié par toutes les scènes d'ennemis
- Patrouille automatique autour d'un point de départ
- Détection du joueur → poursuite
- **Animation d'attaque** : `_do_attack()` joue l'animation, inflige les dégâts après 0.3 s, attend la fin de l'animation avant de rejouer
- Flag `is_attacking` qui bloque l'écrasement d'animation par le mouvement
- Système de vie — `health` initialisé dans `_ready()` depuis `max_health` (fix appliqué)
- Animation `hurt` non interrompue par le mouvement
- Animation de mort + respawn automatique
- Récompense XP + mise à jour des quêtes de type "kill"
- **Barre de vie flottante** : sprite `redbar_00` (vide) à `redbar_06` (plein), 15×7 px affiché ×2 au-dessus de l'ennemi, visible uniquement quand endommagé

**Ennemis disponibles :**
| Scène | Type | Contexte |
|---|---|---|
| `slime.tscn` | Slime vert | Extérieur |
| `skeleton.tscn` | Squelette | Extérieur |
| `golem.tscn` | Golem (boss) | Extérieur |
| `bat.tscn` | Chauve-souris | Grotte |
| `minotaur.tscn` | Minotaure | Extérieur/Grotte |
| `flyingMushroom.tscn` | Champignon volant | Extérieur |

### 🌿 Ressources (Spawn Dynamique)
- `ResourceSpawner` spawne automatiquement plantes ET minerais au démarrage
- Plantes → tiles herbe (source_id 2 et 3) ; Minerais → tiles chemin (source_id 5)
- Vérification de l'outil requis avant récolte
- Respawn après 90 secondes à un **nouvel emplacement aléatoire**
- Maximum simultané par type configurable

**Plantes :** Plante, Tournesol, Champignon, Baie (5 de chaque)

**Minerais** avec système de rareté :
| Minerai | Coups requis | Max simultanés | Rareté |
|---|---|---|---|
| Pierre brute | 3 | 6 | Commun |
| Minerai de fer | 5 | 4 | Peu rare |
| Charbon | 5 | 4 | Peu rare |
| Cristal | 8 | 2 | Rare |
| Minerai d'or | 10 | 2 | Très rare |

Sprites 32×32 extraits du tileset sunnyside (3 variantes visuelles par minerai).

### 🐄 Animaux (Spawn Dynamique)
- `AnimalSpawner` spawne les animaux sur les tiles herbe au démarrage
- Respawn après 120 secondes à un nouvel emplacement après la mort
- Distance minimale de 60 px entre animaux au spawn

**Animaux disponibles :**
| Animal | Max | Drops |
|---|---|---|
| Mouton | 6 | Viande + Peau |
| Vache | 3 | (configurable) |
| Poulet | 12 | (configurable) |

### 📦 Inventaire
- Stockage d'objets avec quantités (dictionnaire)
- Or (gold) avec ajout/soustraction
- Outil équipé (hache / pioche / aucun)
- Slots d'équipement : arme, casque, plastron, bottes, anneau, amulette
- Signal `inventory_changed` pour mettre à jour l'UI
- Utilisation d'items depuis l'UI (potions, viande → soin ; équipements → équipement)
- Déséquipement depuis le panneau personnage

### 📊 Statistiques, Mana & Progression
- 5 statistiques : Force, Endurance, Agilité, Magie, Défense
- Calcul des stats totales = base + bonus équipements
- **Système de mana** : régénération automatique, coût par attaque magique
- Signaux : `mana_changed(current, max)`, `stats_changed`, `level_up(new_level)`
- Montée en niveau automatique + 3 points à distribuer par niveau
- 10 équipements définis dans `Stats.equipment_data`

### 📜 Quêtes
- Deux quêtes : "Chasseur de slimes" (tuer 5 slimes) et "Bûcheron débutant" (récolter 10 bois)
- Système actives / complètes / récompenses réclamées
- Icône de quête au-dessus du PNJ (jaune/blanc/vert selon état)
- Réclamation de récompense via interaction PNJ

### 🧙 PNJ
- Système de dialogue contextuel basé sur l'état de la quête
- Scripts spécialisés (`NPCbucheron.gd`, `NPCslime.gd`) qui étendent `npc.gd`
- Dialogues avec choix multiples (`choices` + `goto`)
- Action `start_quest` déclenchable depuis le dialogue

### 💰 Coffres
- Contenu configurable, persistance de l'état ouvert via `GameManager`

### 🖥️ Interface (HUD)
- **Barre de vie** (rouge), **Barre de mana** (bleue), **Barre XP** (verte) — partagent `character_panel.png`
- **Outil équipé** — icône pixel-art dans un slot dédié
- **Raccourcis clavier visibles** : labels I/P/C superposés sur les boutons HUD
- **Bouton ❓** avec label F1 pour ouvrir le guide
- **Notifications** : panneau semi-transparent animé en haut d'écran, 2.2 s
  - Mauvais outil → orange
  - Level up → doré
  - Équipement équipé → vert clair
- **Guide d'aide (F1)** : overlay plein écran avec toutes les touches classées par section (Déplacement, Combat, Interface, Conseils)
- Panneau inventaire, personnage, équipements, journal de quêtes, boîte de dialogue PNJ

### 🔨 Crafting
- Touche B — deux onglets Armes / Potions
- Recettes :

| Recette | Ingrédients | Résultat |
|---|---|---|
| Épée en bois | 2 Bois | Epee en bois |
| Épée en fer | 3 Minerai de fer | Epee en fer |
| Potion | 1 Plante | Potion |

**Ajouter une recette** dans `scripts/crafting_panel.gd` → section `RECIPES`.

### 💾 Sauvegarde / Chargement
- JSON dans `user://save.json`
- Données : position, vie, inventaire, or, outil, coffres, stats, équipements, niveau/XP, **heure du jour**, **brouillard par scène**
- Compatibilité avec anciennes sauvegardes (vérification des clés)

### 🎨 Menu Principal
- Boutons : Nouvelle Partie (réinitialise tout), Continuer, Quitter
- "Continuer" désactivé si pas de sauvegarde

---

## ⚠️ Points d'attention

- `rock.tscn` est encore référencé dans `cave.tscn` (ressource statique legacy) — peut être remplacé par ResourceSpawner dans la grotte si souhaité
- `health_bar.gd` est présent mais n'est plus utilisé (la barre de vie ennemi est maintenant gérée directement dans `enemy.gd`)

---

## 📈 Historique des commits (récents → anciens)

| Commit | Description |
|---|---|
| `1bac24f` | Amélioration attaque ennemis (animation + health bar flottante) |
| `4399336` | Modifications diverses |
| `5fae94c` | Ajout ennemis (Golem, Bat, Minotaure, FlyingMushroom) |
| `044342b` | Corrections |
| `6619cf0` | Modification minerais (sprites 32×32, rareté) |
| `1cb975d` | ResourceSpawner |
| `c509e25` | Modification PNJ |
| `6c35627` | Dialogue amélioré (choices/goto) |
| `16881fa` | Ajout PNJ dialogue |
| `2d53077` | Cycle jour/nuit |
| `d4b3ac1` | Fog of war par scène |
| `36f14fa` | Fog of war |
| `07c2ba7` | Grotte avec passage (portail + SceneTransition) |
| `a52e833` | Attaque arc et magie, visuel |
| `f6e53cf` | Crafting panel + mana + arc |
| `fcadec6` | Ajout panel craft |
| `0266fea` | Modification buttons |

---

## 🔭 Pistes d'évolution

### 🎯 Dans la continuité directe

**Combat & ennemis**
- Ennemis à distance : archer squelette ou mage — `projectile.gd` existe déjà côté joueur, il suffit de l'utiliser côté ennemi

**Spawns & monde**
- ResourceSpawner dans la grotte (actuellement rochers statiques)
- Nouvelles zones accessibles via portail (donjon, village, désert…)

**Crafting & économie**
- Nouvelles recettes utilisant Pierre brute, Cristal, Or
- Amélioration d'équipements : dépenser des minerais pour upgrader une arme (+1, +2…)

**Quêtes**
- Type "deliver" : apporter X items à un PNJ (trivial à ajouter dans `quest_manager.gd`)
- Chaîne de quêtes : une quête qui en débloque une autre chez le même PNJ
- Quêtes avec timer : défendre un point, chasser X ennemis avant la nuit

### 🧠 Profondeur RPG

- **Classes au démarrage** : Guerrier / Archer / Mage — stats de départ et arme initiale différentes
- **Statuts** : empoisonné (dégâts sur la durée), ralenti, régénération — le système de dégâts continus des ennemis est déjà en place, c'est le même principe inversé

### 🔊 Audio (fort impact, effort moyen)

- Sons d'attaque, récolte, pas selon le sol
- Musique d'ambiance différente extérieur/grotte, fondu enchaîné
- Son de level up, notification, ouverture de coffre

### 🖥️ QoL interface

- **Tooltips** : hover sur un équipement → stats + comparaison avec l'équipé
- **Barre de raccourcis consommables** : 1-4 pour potions/viande sans ouvrir l'inventaire
- **Indicateur de l'heure** : afficher jour/nuit avec une icône soleil/lune (l'heure est déjà dans `SunLabel`)

---

## 🏗️ Plan d'implémentation — Prochaines fonctionnalités

### 1. 🌟 Talents passifs

**Concept** : tous les 3 niveaux, le jeu propose 3 talents aléatoires parmi un pool. Le joueur en choisit un, qui s'applique immédiatement et définitivement.

**Fichiers touchés :** `stats.gd`, `hud.gd`

**Plan détaillé :**

**`stats.gd`**
- Ajouter `const TALENT_EVERY_N_LEVELS = 3` et `var active_talents: Array = []`
- Ajouter un nouveau signal `signal talent_available(choices: Array)`
- Dans `_level_up()` : si `level % TALENT_EVERY_N_LEVELS == 0`, piocher 3 talents aléatoires distincts dans le pool et émettre `talent_available`
- Ajouter `func apply_talent(talent_id: String)` qui stocke le talent et applique son effet sur les stats (ou sur un dictionnaire de flags)
- Ajouter `func has_talent(talent_id: String) -> bool`

Pool de talents (exemples) :
```gdscript
const TALENT_POOL = [
    { "id": "regen_on_kill",   "label": "Vampire",          "desc": "+5 PV à chaque kill" },
    { "id": "speed_boost",     "label": "Leste",            "desc": "Vitesse +15%" },
    { "id": "piercing_arrows", "label": "Flèches perçantes","desc": "Les flèches traversent les ennemis" },
    { "id": "max_health_up",   "label": "Robuste",          "desc": "PV max +30" },
    { "id": "crit_chance",     "label": "Précision",        "desc": "20% de chances de coup critique (×1.5)" },
    { "id": "mana_regen_up",   "label": "Mystique",         "desc": "Régén mana ×2" },
    { "id": "double_loot",     "label": "Chanceux",         "desc": "Les ressources donnent ×2 objets" },
    { "id": "dash_heal",       "label": "Esquiveur",        "desc": "+3 PV à chaque esquive réussie" },
]
```

**`hud.gd`**
- Connecter le signal `Stats.talent_available` dans `_ready()`
- Ajouter `_build_talent_panel()` et `_show_talent_choices(choices)` : overlay sombre avec 3 grandes cartes cliquables (icône + nom + description)
- Le panneau est bloquant (pause le temps de la sélection via `get_tree().paused = true`) ou simplement non-fermable
- À la sélection : `Stats.apply_talent(id)` + fermer + notification dorée "🌟 Talent acquis : ..."
- Afficher les talents actifs dans le panneau personnage (section dédiée en bas)

**Sauvegarde** : ajouter `active_talents` dans `GameManager.save_game()` et `load_game()`

---

### 2. 💀 Boss avec barre de vie dédiée

**Concept** : certains ennemis sont marqués comme "boss". Quand ils sont en vie, une barre de vie stylisée apparaît en bas de l'écran. À la mort, ils droppent des items uniques et ne respawnent pas (ou très longtemps).

**Fichiers touchés :** `enemy.gd`, `hud.gd`

**Plan détaillé :**

**`enemy.gd`**
- Ajouter les exports :
```gdscript
@export var is_boss: bool = false
@export var boss_name: String = "Boss"
@export var unique_drops: Array = []
# Format : [{ "name": "Clé de donjon", "qty": 1 }, { "name": "Minerai d'or", "qty": 3 }]
```
- Dans `_ready()` : si `is_boss`, émettre un signal `boss_spawned(self)` vers le groupe "hud"
- Ajouter un signal `boss_health_changed(current, max_hp)` émis dans `take_damage()` et `respawn()`
- Dans `die()` : si `is_boss`, distribuer `unique_drops` (via `Inventory.add_item`), émettre `boss_died`, et utiliser un `respawn_time` très long (ou ne pas respawner du tout avec un flag `respawn_enabled = not is_boss`)
- Les bosses actuels à configurer : `golem.tscn` (is_boss=true, boss_name="Golem de Pierre")

**`hud.gd`**
- Ajouter `_build_boss_bar()` dans `_ready()` : barre en bas d'écran (CanvasLayer), cachée par défaut
- La barre contient : nom du boss (Label), barre de progression stylisée (TextureProgressBar ou ColorRect), icône de tête de mort
- Style : fond noir avec bordure rouge/or, plus grand que la barre de vie joueur
- Connecter les signaux boss via le groupe "hud" :
  - `boss_spawned` → afficher la barre, fill = 100%
  - `boss_health_changed` → mettre à jour le fill
  - `boss_died` → animation de remplissage à 0 puis disparition progressive

---

### 3. ⚡ Esquive / Roulade

**Concept** : double-tap sur une direction directionnelle = dash d'invincibilité court dans cette direction. Cooldown de 1 seconde. Animation de "flash" blanc.

**Fichiers touchés :** `player.gd`

**Plan détaillé :**

```gdscript
# Variables à ajouter dans player.gd
var _last_direction_press: Vector2 = Vector2.ZERO
var _last_direction_time:  float   = 0.0
const DOUBLE_TAP_WINDOW:   float   = 0.25   # secondes
var _is_dodging:           bool    = false
var _dodge_cooldown:       float   = 0.0
const DODGE_COOLDOWN:      float   = 1.0    # secondes
const DODGE_SPEED:         float   = 400.0
const DODGE_DURATION:      float   = 0.18   # secondes d'invincibilité
```

**Détection du double-tap** dans `_input()` :
- À chaque `is_action_just_pressed` directionnel, comparer avec `_last_direction_press`
- Si même direction et `Time.get_ticks_msec() - _last_direction_time < DOUBLE_TAP_WINDOW * 1000` → déclencher le dodge
- Mémoriser la direction et l'heure à chaque appui

**`_dodge(direction)`** :
1. Vérifier le cooldown et qu'on n'est pas déjà en train d'attaquer ou de se faire toucher
2. `_is_dodging = true` → immunité dans `take_damage()` (comme `is_attacking`)
3. Appliquer `velocity = direction * DODGE_SPEED` pendant `DODGE_DURATION`
4. Effet visuel : `modulate = Color(1, 1, 1, 0.5)` pendant le dash + retour
5. Si le talent `dash_heal` est actif : `heal(3)`
6. Après `DODGE_DURATION` : `_is_dodging = false`, démarrer le cooldown
7. Le cooldown décrémente dans `_physics_process(delta)`

**Dans `take_damage()`** : ajouter `if _is_dodging: return`

**Touche** : le double-tap sur les flèches directionnelles est naturel. Pas besoin d'une touche dédiée.

---

### 4. 🗺️ Minimap

**Concept** : petit widget en coin de l'écran (bas-droite) montrant une version miniature du brouillard de guerre révélé, avec un point blanc pour le joueur.

**Fichiers touchés :** `hud.gd` (ou nouveau `minimap.gd` attaché au HUD)

**Plan détaillé :**

La minimap réutilise directement `fog_of_war.revealed_cells` pour connaître les zones révélées.

**Approche avec `SubViewportContainer`** (la plus propre) :
- Créer un `SubViewport` qui capture la scène depuis le dessus avec un zoom très réduit — mais complexe à mettre en place.

**Approche recommandée — rendu direct sur `Control`** :
- Ajouter `_build_minimap()` dans `hud.gd` créant un `TextureRect` en coin bas-droite (taille 120×120 px)
- Créer une `Image` de `MAP_W × MAP_H` pixels (même dimensions que le fog), reconstruite régulièrement
- Copier les données de `fog_of_war.revealed_cells` : pixel noir = non révélé, pixel coloré = révélé (herbe = vert foncé, chemin = beige, eau = bleu)
- Point blanc clignotant = position joueur, points rouges = ennemis proches
- Mise à jour toutes les 0.5 secondes (pas besoin de frame-perfect)
- Bordure pixel-art autour du widget

```gdscript
# Dans hud.gd — variables à ajouter
var _minimap_rect: TextureRect = null
var _minimap_image: Image = null
var _minimap_texture: ImageTexture = null
var _minimap_timer: float = 0.0
const MINIMAP_UPDATE_INTERVAL: float = 0.5
const MINIMAP_SIZE: int = 120  # pixels affichés

# Couleurs de tuile sur la minimap
const MINIMAP_COLORS = {
    "revealed":     Color(0.25, 0.45, 0.20),  # vert foncé (herbe révélée)
    "fog":          Color(0.05, 0.05, 0.05),  # presque noir
    "player":       Color(1.0, 1.0, 1.0),     # blanc
    "enemy":        Color(1.0, 0.2, 0.2),     # rouge
}
```

**Mise à jour** dans `_process(delta)` du HUD : incrémenter `_minimap_timer`, si > `MINIMAP_UPDATE_INTERVAL`, appeler `_update_minimap()` et remettre à zéro.

**`_update_minimap()`** :
1. Récupérer le nœud fog via `get_tree().get_first_node_in_group("fog")`
2. Pour chaque pixel de la minimap : mapper vers les coordonnées du fog, lire l'alpha de `revealed_cells`
3. Si révélé (alpha < 0.5) → couleur terrain, sinon couleur fog
4. Poser le point joueur (calculer sa position en pixels de minimap)
5. Poser les points ennemis visibles
6. `_minimap_texture.update(_minimap_image)`

**Toggle** : touche **M** pour afficher/masquer (à ajouter dans `_input()` du HUD et dans le guide F1)

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             