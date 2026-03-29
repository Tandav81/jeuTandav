# 📋 Récapitulatif du projet — testJeu2D

> Godot 4.6 — Jeu 2D RPG (top-down)
> Dernière mise à jour : 2026-03-29

---

## 🗂️ Structure du projet

```
test-jeu-2d/
├── project.godot
├── scenes/
│   ├── world.tscn            ← scène principale du jeu
│   ├── main_menu.tscn        ← menu principal
│   ├── player.tscn           ← personnage joueur
│   ├── npc.tscn              ← PNJ donneur de quêtes
│   ├── enemySlime.tscn       ← ennemi Slime
│   ├── enemySkeleton.tscn    ← ennemi Squelette
│   ├── chest.tscn            ← coffre interactif
│   ├── item.tscn             ← objet ramassable
│   ├── mouton.tscn           ← animal (mouton)
│   ├── vache.tscn            ← animal (vache)
│   ├── rock.tscn             ← ressource (minerai)
│   ├── tree.tscn             ← ressource (bois)
│   └── procedural_map_2d.tscn ← carte générée procéduralement
├── scripts/
│   ├── player.gd
│   ├── enemy.gd
│   ├── npc.gd
│   ├── animal.gd
│   ├── chest.gd
│   ├── item.gd
│   ├── resource.gd
│   ├── hud.gd
│   ├── health_bar.gd         ← ⚠️ obsolète (voir section bugs)
│   ├── main_menu.gd
│   ├── procedural_map_2d.gd
│   ├── game_manager.gd       ← Autoload
│   ├── inventory.gd          ← Autoload
│   ├── quest_manager.gd      ← Autoload
│   └── stats.gd              ← Autoload
└── assets/
    ├── sprites/
    └── menus/
```

**Autoloads enregistrés :**
- `GameManager` — gestion de la sauvegarde, position de spawn, état des coffres
- `Inventory` — inventaire, or, outils, équipements
- `QuestManager` — quêtes actives/complètes, progression
- `Stats` — niveau, XP, statistiques de personnage, données d'équipements

**Touches configurées :**
| Action | Touche |
|---|---|
| Déplacement | Flèches directionnelles |
| Attaque | Espace |
| Interagir | E |
| Outil suivant | T |
| Panneau personnage / Journal | C |
| Sauvegarder | S |
| Fermer menu | Échap |

---

## ✅ Fonctionnalités implémentées

### 🎮 Joueur
- Déplacement en 4 directions avec animations (marche, idle, attaque, outils)
- Système de vie avec signal `health_changed`
- Attaque au corps à corps avec zone de collision directionnelle (`AttackZone`)
- Invincibilité pendant l'attaque
- Utilisation d'outils orientés (hache, pioche) avec animations dédiées
- Changement d'outil via touche T (cycle : aucun → hache → pioche → aucun)
- Guérison via potions et viande
- Respawn à une position sauvegardée au démarrage

### 🗺️ Monde
- Génération procédurale de carte 2D (80×80 tuiles) avec seed
- 4 biomes : EAU, SABLE, FORÊT, ROCHE
- Transitions automatiques entre biomes via `set_cells_terrain_connect`
- Logique de placement de villages (positions calculées, instances commentées)

### 👾 Ennemis
- Patrouille automatique autour d'un point de départ
- Détection du joueur dans un rayon configurable → poursuite
- Dégâts continus au contact (damage per second)
- Système de vie + animation de mort
- Respawn automatique après délai configurable
- Récompense en XP à la mort
- Mise à jour des quêtes de type "kill" à la mort
- Deux types disponibles : Slime, Squelette (configurés via `@export enemy_type`)

### 🌿 Ressources & Animaux
- Arbres et rochers avec système de coups nécessaires (`health`)
- Vérification de l'outil requis avant récolte
- Animation de "hit" au contact
- Récolte automatique quand `health <= 0` → ajout à l'inventaire
- Mise à jour des quêtes de type "collect"
- Respawn optionnel des ressources
- Animaux (mouton, vache) qui fuient le joueur
- Les animaux donnent de la viande quand leur vie tombe à 0

### 📦 Inventaire
- Stockage d'objets avec quantités (dictionnaire)
- Or (gold) avec ajout/soustraction
- Outil équipé (hache / pioche / aucun)
- Slots d'équipement : arme, casque, plastron, bottes, anneau, amulette
- Signal `inventory_changed` pour mettre à jour l'UI
- Utilisation d'items depuis l'UI (potions, viande → soin ; équipements → équipement)
- Déséquipement depuis le panneau personnage

### 📊 Statistiques & Progression
- 5 statistiques : Force, Endurance, Agilité, Magie, Défense
- Calcul des stats totales = base + bonus équipements
- Formules dérivées : vie max, dégâts, vitesse de déplacement
- Système de niveaux et XP avec montée en niveau automatique
- 3 points à distribuer par niveau
- Signal `level_up` et `stats_changed`
- 8 équipements définis dans `Stats.equipment_data` avec leurs bonus

### 📜 Quêtes
- Deux quêtes implémentées : "Chasseur de slimes" (tuer 5 slimes) et "Bûcheron débutant" (récolter 10 bois)
- Système de quêtes actives / complètes / récompenses réclamées
- Démarrage de quête via interaction avec un PNJ
- Icône de quête au-dessus du PNJ (jaune = disponible, blanc = en cours, vert = récompense disponible)
- Réclamation de récompense via interaction avec le PNJ une fois la quête terminée
- Récompenses : XP, or, items
- Journal de quêtes accessible via touche C ou bouton HUD

### 🧙 PNJ
- Zone d'interaction avec détection du joueur
- Dialogue contextuel selon l'état de la quête
- Icône flottante dynamique selon l'état
- `quest_id` configurable par export (un PNJ par quête)

### 💰 Coffres
- Coffre avec animation ouverture/fermé
- Contenu configurable : potion, or, ou item quelconque
- Persistance de l'état ouvert via `GameManager.coffres_ouverts`
- Zone d'interaction

### 🖥️ Interface (HUD)
- Barre de vie du joueur
- Panneau inventaire (grille d'items avec icônes/sprites, or, outil équipé)
- Panneau personnage (stats avec couleurs, barre XP, boutons "+" pour dépenser les points)
- Panneau équipements (6 slots avec déséquipement au clic)
- Journal de quêtes avec progression
- Boîte de dialogue pour les PNJ
- Boutons HUD : Inventaire, Personnage, Quêtes

### 💾 Sauvegarde / Chargement
- Sauvegarde JSON dans `user://save.json`
- Données sauvegardées : position, vie, inventaire, or, outil, coffres ouverts, stats, équipements
- Compatibilité avec anciennes sauvegardes (vérification des clés)
- Chargement au menu principal via "Continuer"
- Bouton "Continuer" désactivé si aucune sauvegarde

### 🎨 Menu Principal
- Boutons : Nouvelle Partie, Continuer, Quitter
- "Continuer" désactivé si pas de sauvegarde
- Réinitialisation de l'état du jeu à "Nouvelle Partie"

---

## ⚠️ Bugs et code obsolète identifiés

### 🔴 Critique

#### 1. `health_bar.gd` — Script obsolète non attaché
Le fichier `scripts/health_bar.gd` existe mais **n'est attaché à aucune scène**. Il contient des erreurs qui le rendraient non fonctionnel :
- `get_tree()` appelé au niveau classe (hors `_ready()`) → crash au chargement
- Signal `healthChanged` n'existe pas dans `player.gd` (le bon nom est `health_changed`)
- Variables `currentHealth` et `maxHealth` n'existent pas (ce sont `health` et `max_health`)

La barre de vie est correctement gérée par `hud.gd` via `_on_health_changed()`.

**→ Action : supprimer `scripts/health_bar.gd`**

---

### 🟠 Important

#### 2. `hud.gd` — Code mort dans `get_item_texture()`
Après le dernier `return null` de la fonction `get_item_texture()`, il reste du code inaccessible (une ancienne version de `update_quest_journal`) qui ne sera jamais exécuté :

```gdscript
func get_item_texture(item_name: String) -> Texture2D:
    ...
    return null   # ← tout ce qui suit est mort
    # Nettoyer
    for child in quest_liste.get_children():   # jamais exécuté
        child.queue_free()
    for quest in QuestManager.active_quests:   # jamais exécuté
        ...
```

**→ Action : supprimer les lignes mortes après `return null`**

#### 3. `main_menu.gd` — "Nouvelle Partie" ne réinitialise pas les Stats
Quand le joueur clique "Nouvelle Partie", les autoloads `Stats` ne sont pas remis à zéro ni `Inventory.equipped` :

```gdscript
# Ce qui est réinitialisé ✅
GameManager.spawn_position = Vector2.ZERO
GameManager.player_health = 100
GameManager.coffres_ouverts = []
Inventory.items = {}
Inventory.gold = 0
Inventory.equipped_tool = ""
QuestManager.active_quests = []
QuestManager.completed_quests = []

# Ce qui MANQUE ❌
Inventory.equipped = {"arme": null, "casque": null, ...}
Stats.level = 1
Stats.xp = 0
Stats.xp_next_level = 100
Stats.stat_points = 0
Stats.base_force = 5
Stats.base_endurance = 5
Stats.base_agilite = 5
Stats.base_magie = 5
Stats.base_defense = 5
```

**→ Action : ajouter la réinitialisation de `Stats` et `Inventory.equipped` dans `_on_btn_nouvelle_partie_pressed()`**

---

### 🟡 Mineur

#### 4. `procedural_map_2d.gd` — Fonctions inutilisées / villages vides
- `_choisir_tuile()` est définie mais jamais appelée (remplacée par `set_cells_terrain_connect`)
- `_generate_village()` calcule des positions mais l'appel `_placer_maison()` est commenté → les villages ne sont jamais instanciés visuellement
- Ancienne `_apply_tiles()` commentée en bloc

**→ Action : supprimer `_choisir_tuile()` et l'ancienne `_apply_tiles()` commentée ; décider si les villages doivent être activés**

#### 5. `animal.gd` — Signal `resource_collected` émis mais jamais connecté
Le signal est émis puis l'item est aussi ajouté directement via `Inventory.add_item()`. La ligne `emit_signal(...)` est un reliquat d'une architecture précédente.

```gdscript
emit_signal("resource_collected", "animal", resource_name, quantity)  # reliquat
Inventory.add_item(resource_name, quantity)  # ← la vraie ligne active
```

**→ Action : supprimer la ligne `emit_signal` dans `animal.gd`**

#### 6. `npc.gd` — Prints de debug non nettoyés
Plusieurs `print()` de débogage subsistent :
- `print("NPC quest_id =", quest_id)`
- `print("update quest icon")` + `print("Quête disponible")` etc.

**→ Action : supprimer ou commenter ces prints**

#### 7. `player.gd` — `max_health` non synchronisé au démarrage
`max_health` est hardcodé à `100` dans `player.gd`. Si les stats de base d'endurance changent (via `Stats`), le max_health réel du joueur n'est pas recalculé au démarrage. Il est mis à jour depuis `hud.gd` uniquement lorsqu'on dépense un point d'endurance.

**→ Action : dans `player._ready()`, ajouter `max_health = Stats.get_max_health()`**

#### 8. Fichiers `.tmp` dans le dossier `scenes/`
Deux fichiers temporaires de Godot sont présents et ne devraient pas être versionnés :
- `world.tscn86707209802.tmp`
- `procedural_map_2d.tscn40335090267.tmp`

**→ Action : ajouter `*.tmp` au `.gitignore`**

---

## 📈 Historique des commits

| Commit | Description |
|---|---|
| `0266fea` | modif buttons |
| `d149e84` | modif menus |
| `758b20c` | fonctionne avec une quête |
| `db7c7fd` | nettoyage 2 |
| `8e5d9c6` | nettoyage |
| `f097eab` | btn journal quete |
| `5da919c` | refacto |
| `b587972` | NPC + quête |
| `36b391a` | stats perso |
| `aa7889d` | mouton |
| `5e101c1` | menu principal |
| `5675d74` | ajout inventaire |
| `26777b9` | ajout |
| `d3942f2` | modified |
| `d145b82` | init |
| `38a4240` | first commit |

---

## 🔨 Système de Crafting

### Fonctionnement (v2 — positionnement absolu sur spritesheet)
- Touche **B** (ou Échap) : ouvre/ferme le panneau de crafting
- Deux onglets **Armes** / **Potions** : boutons invisibles positionnés sur les icônes du spritesheet (pas de texte par-dessus)
- Le fond utilise `assets/menus/Craft.png` col 2 — le sprite change automatiquement pour indiquer l'onglet actif
- Zone GAUCHE : liste des recettes sous forme d'icônes carrées (cases style inventaire, grille 3 colonnes)
- Zone DROITE : ingrédients requis (icône + quantité verte/rouge) et objet résultant
- Bouton **CRÉER** transparent superposé exactement sur le bouton CREATE du spritesheet
- Message de confirmation (2,5 s) après fabrication

### Recettes implémentées
| Recette | Ingrédients | Résultat |
|---|---|---|
| Épée en bois | 2 Bois | Epee en bois |

### Ajouter de nouvelles recettes
Dans `scripts/crafting_panel.gd`, section `RECIPES` :
```gdscript
const RECIPES = {
    "armes": [
        {"name": "Epee en bois",  "ingredients": {"Bois": 2},          "result": "Epee en bois",  "result_qty": 1},
        {"name": "Epee en fer",   "ingredients": {"Minerai": 3},        "result": "Epee en fer",   "result_qty": 1},
        # ajouter ici...
    ],
    "potions": [
        {"name": "Potion",        "ingredients": {"Plante": 1},         "result": "Potion",        "result_qty": 1},
    ],
}
```
Pour ajouter une icône au résultat ou à un ingrédient, ajouter l'entrée dans `ITEM_REGIONS` (si issu de `rpgItems.png`) ou `ITEM_IMAGES` (si c'est un fichier PNG dédié).

### Layout absolu (mesures en pixels Craft.png à l'échelle 1×, ×3 à l'écran)
| Zone | x (1×) | y (1×) | Contenu |
|---|---|---|---|
| Onglet Armes | 14–33 | 8–27 | Bouton invisible sur icône T verte |
| Onglet Potions | 32–51 | 8–27 | Bouton invisible sur icône mortier verte |
| Liste recettes | 10–68 | 28–117 | GridContainer d'icônes carrées 48×48 |
| Détail recette | 138–196 | 10–65 | Ingrédients + résultat |
| Bouton CRÉER | 83–123 | 66–83 | Bouton transparent sur sprite CREATE |
| Feedback | 72–134 | 84–115 | Message succès/erreur (2,5 s) |

### Fichiers concernés
- `scripts/crafting_panel.gd` ← v2 (positionnement absolu, fixes visuels)
- `scripts/hud.gd` ← 4 lignes ajoutées (instantiation, touche B, Échap)

---

## 🔭 Pistes d'évolution possibles

- ~~Système de crafting~~ ✅ implémenté (étape 1 : Épée en bois)
- Ajouter d'autres recettes de crafting (Épée en fer, Potion, Bâton magique…)
- Ajouter un objet "Enclume" placé dans le monde (interaction E pour ouvrir le panneau)
- Activer les villages sur la carte procédurale (décommenter `_placer_maison`)
- Ajouter d'autres quêtes dans `QuestManager.QUESTS`
- Système de dialogues plus élaboré (plusieurs lignes, choix)
- Ennemis supplémentaires avec comportements différents
- Sons et musique
- Système de crafting (avec le bois et le minerai récoltés)
- Plusieurs zones/scènes avec transitions
- Sauvegarde de la progression des quêtes
