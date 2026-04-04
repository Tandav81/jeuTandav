# 📋 Récapitulatif du projet — testJeu2D

> Godot 4.6 — Jeu 2D RPG (top-down)
> Dernière mise à jour : 2026-04-04 (session 2)

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
│   └── npc_merchant.gd             ← PNJ marchand (extends npc.gd)
└── assets/
	├── Player/                     ← spritesheets joueur (attaque, arc…)
	├── Enemies/                    ← Bat/, Golem_1/, flyingMushroom/, etc.
	├── Animals/                    ← Chicken/, etc.
	├── sprites/                    ← redbar_00 à redbar_06 (barre de vie ennemis)
	├── Tileset/                    ← spr_tileset_sunnysideworld_16px.png
	├── menus/                      ← character_panel.png (HUD barres), Equipment.png (panneau équipement visuel 160×384 px)
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
| Équipement visuel | G |
| Journal de quêtes | C |
| Sauvegarder | S |
| Guide d'aide | F1 |
| Fermer menu | Échap |
| Minimap on/off | M |

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
- **Talent flèches perçantes** : si `piercing_arrows` actif, la flèche traverse les ennemis (liste `_hit_bodies` pour éviter les doubles coups)

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
- Détection du joueur → poursuite jusqu'à `attack_range` pixels, puis **arrêt complet** — l'ennemi ne traverse plus le joueur
- **Portée d'attaque** (`attack_range`, défaut 38 px) : en dessous de cette distance, `player_in_range = true`, vitesse = 0, attaques déclenchées ; au-delà, l'ennemi se remet en mouvement
- **Animation d'attaque** : `_do_attack()` joue l'animation, inflige les dégâts après 0.3 s, attend la fin de l'animation avant de rejouer
- Flag `is_attacking` qui bloque l'écrasement d'animation par le mouvement
- Système de vie — `health` initialisé dans `_ready()` depuis `max_health` (fix appliqué)
- Animation `hurt` non interrompue par le mouvement
- Animation de mort + respawn automatique
- Récompense XP + mise à jour des quêtes de type "kill"
- **Barre de vie flottante** : sprite `redbar_00` (vide) à `redbar_06` (plein), 15×7 px affiché ×2 au-dessus de l'ennemi, visible uniquement quand endommagé
- **Système Boss** : `@export var is_boss`, `boss_name`, `unique_drops` (tableau `[{name, qty}]`) — drops uniques à la mort, signal vers HUD, respawn configurable
- Talent `crit_chance` appliqué dans `take_damage()` (20% × 1.5)
- Talent `regen_on_kill` : le joueur regagne 5 PV à chaque kill

**Ennemis disponibles :**
| Scène | Type | Contexte |
|---|---|---|
| `slime.tscn` | Slime vert | Extérieur (jour) |
| `skeleton.tscn` | Squelette | Extérieur (jour + nuit) |
| `golem.tscn` | Golem (boss) | Extérieur |
| `bat.tscn` | Chauve-souris | Grotte + Nuit |
| `minotaur.tscn` | Minotaure | Extérieur/Grotte |
| `flyingMushroom.tscn` | Champignon volant | Extérieur (jour) |

**Spawn dynamique diurne (`day_enemy_spawner.gd`) :**
- Nœud `DayEnemySpawner` ajouté dans `world.tscn` (même architecture que le spawner nocturne)
- Apparaît à l'aube/jour, disparaît en fondu à la nuit (fade 1.2 s)
- Placement **aléatoire** sur les tiles herbe (source_id 2, 3)
- Config dans `DAY_ENEMY_DEFS` : `scene`, `max`, `overrides` — quantité et type entièrement configurables
- Distance sécurité joueur : 220 px — distance min entre ennemis : 80 px

**Spawn dynamique nocturne (`night_enemy_spawner.gd`) :**
- Apparaît à la nuit, disparaît à l'aube (fade 1.5 s)
- Config dans `NIGHT_ENEMY_DEFS` : `scene`, `max`, `overrides`
- Distance sécurité joueur : 200 px — distance min entre ennemis : 80 px
- Spawn sur tiles herbe + chemin (source_id 2, 3, 5)

### 🌿 Ressources (Spawn Dynamique)
- `ResourceSpawner` spawne automatiquement plantes ET minerais au démarrage
- **Talent double_loot** : la quantité récoltée est doublée (`final_qty = quantity * 2`)
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

### 🌳 Arbres (Spawn Dynamique)
- Intégré dans `ResourceSpawner` (plus de nœud `TreeSpawner` séparé)
- Positionnement **entièrement aléatoire** à chaque lancement (pas de graine fixe)
- Nombre configurable via `TREE_COUNT` (défaut : **30**), distance min entre arbres : 48 px
- Les arbres utilisent `resource.gd` : coupure à la hache, respawn en place après 30 s, donne 2 Bois
- Support de plusieurs types d'arbres avec système de **poids** (`weight`) pour la fréquence relative
- Config dans `TREE_DEFS` : `scene`, `weight`, `overrides`

### 💰 Coffres (Spawn Dynamique — Respawnable)
- Intégré dans `ResourceSpawner` (plus de nœud `ChestSpawner` séparé)
- Maximum **5 coffres simultanés** sur la carte (`MAX_CHESTS = 5`), placement aléatoire sur les tiles herbe
- Récompense **entièrement aléatoire** tirée d'une table pondérée (`CHEST_REWARDS`) :

| Récompense | Poids |
|---|---|
| Potion × 1 | 35 |
| 15 pièces d'or | 25 |
| Minerai de fer × 2 | 20 |
| 30 pièces d'or | 12 |
| Grande potion × 1 | 5 |
| Cristal × 1 | 3 |

- Après ouverture : animation "ouvert" 2 s → `queue_free()` → nouveau coffre spawn après **600 secondes** (10 min)
- `chest.gd` : nouveau signal `chest_opened` + export `is_respawnable` (true pour les coffres ResourceSpawner, false pour les coffres permanents legacy)
- Les coffres respawnables sont ajoutés au groupe `"spawned_chest"` (comptage pour le max)

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

### 🌟 Talents Passifs
- Tous les 3 niveaux, 3 talents sont proposés (choix parmi ceux non encore acquis)
- Panneau de sélection bloquant (jeu en pause) avec cartes cliquables
- Pool de 8 talents :

| ID | Label | Effet |
|---|---|---|
| `regen_on_kill` | Vampire | +5 PV à chaque kill ennemi |
| `speed_boost` | Leste | Vitesse de déplacement +15% |
| `piercing_arrows` | Flèches perçantes | Les flèches traversent les ennemis |
| `max_health_up` | Robuste | PV maximum +30 |
| `crit_chance` | Précision | 20% de chances de coup critique (×1.5) |
| `mana_regen_up` | Mystique | Régénération de mana ×2 |
| `double_loot` | Chanceux | Les ressources récoltées donnent ×2 objets |
| `dash_heal` | Esquiveur | +3 PV à chaque esquive réussie |

- Sauvegardé dans `GameManager` (champ `active_talents`)
- Talents visibles dans le panneau personnage (section dédiée)

### ⚡ Esquive / Roulade
- Double-tap sur une flèche directionnelle = dash d'invincibilité (0.18 s)
- Vitesse de dash : 420 px/s, cooldown : 1 s
- Flash semi-transparent pendant le dash
- Immunité aux dégâts (`_is_dodging` flag dans `take_damage()`)
- Talent `dash_heal` : +3 PV par esquive réussie

### 💀 Boss — Barre de vie dédiée
- Exports sur `enemy.gd` : `is_boss`, `boss_name`, `unique_drops`
- Barre de vie stylisée en bas d'écran (fond rouge → fill sombre)
- Signaux : `boss_health_changed(current, max_hp)`, `boss_died`
- À la mort : drops uniques distribués via `Inventory.add_item()`, barre disparaît
- Au respawn : barre réapparaît avec vie pleine
- **Configuration** : dans `golem.tscn`, cocher `is_boss = true`, renseigner `boss_name` et `unique_drops` dans l'inspecteur Godot

### 🗺️ Minimap
- Widget `TextureRect` 120×120 px en haut-droite (CanvasLayer)
- Rendu pixel-par-pixel sur une `Image` mise à jour toutes les 0.5 s
- Réutilise `fog_of_war.revealed_cells` : zones révélées en vert, brouillard en quasi-noir
- Point blanc = joueur, points rouges = ennemis dans les zones révélées
- Toggle avec la touche **M**

### 🏅 Icônes de talents actifs (HUD)
- Rangée de petits carrés colorés (24×24 px) affichée sous les barres de vie/mana/xp
- Un carré par talent actif, avec une couleur et une abréviation 2 lettres distinctes par talent
- Tooltip au survol affichant le nom complet et l'effet
- Se met à jour automatiquement à l'acquisition d'un talent et au chargement d'une sauvegarde
- Configuration dans `hud.gd` → constante `TALENT_ICON_DEFS` (id → couleur + abréviation + description)

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
- Navigation clavier complète dans les choix : ↑/↓ pour déplacer le curseur, **E** ou **Entrée** pour valider, **1–9** pour sélection directe rapide
- Le choix actif est mis en évidence visuellement (bordure dorée épaisse + préfixe ▶ + texte jaune vif)
- Déplacement du joueur bloqué automatiquement pendant le dialogue (`player.in_dialogue = true`) — rétabli à la fin ou si `force_end_dialogue()` est appelé

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
- **Guide d'aide (F1)** : overlay plein écran avec toutes les touches classées par section (Déplacement, Combat, Interface, Conseils). Inclut désormais la touche **G** (Équipement visuel).
- Panneau inventaire, personnage, équipements (texte), journal de quêtes, boîte de dialogue PNJ
- **Dialogue PNJ** : boîte de dialogue entièrement jouable au clavier — avancer avec **E**, naviguer les choix avec **↑/↓**, valider avec **E** ou **Entrée**, sélection directe via **1–9**

### 🪖 Panneau d'équipement visuel (`equipment_panel.gd`)
- Ouverture/fermeture via la touche **G** (Gear)
- Construit entièrement par code, instancié dans `hud.gd` via `_build_equipment_panel()`
- **Fond visuel** : `assets/menus/Equipment.png` (panneau 1, région `Rect2(0,0,160,88)`) affiché en 640×352 px (×4, `TEXTURE_FILTER_NEAREST`) + barre de détail sombre de 36 px — taille totale : **640×388 px**
- **Bouton fermer** : zone cliquable transparente (sans texte) superposée au X dessiné dans l'image (natif x=144..150, y=3..9 → ×4 : position=Vector2(576,12), taille=28×28 px) — aucun élément UI visible ajouté
- **Zone personnage** (section gauche) — 7 slots pixel-perfect sur les cadres dessinés dans l'image :
  - Positions et tailles déterminées par analyse pixel du PNG (constantes `SLOT_POSITIONS`, `SLOT_SIZES`) :
    - `casque` : pos=(132,68) taille=56×56 — `bouclier` : pos=(68,132) taille=52×56
    - `plastron` : pos=(120,132) taille=84×56 — `arme` : pos=(204,132) taille=48×56
    - `bottes` : pos=(132,196) taille=56×56 — `anneau` : pos=(68,260) taille=48×56
    - `amulette` : pos=(204,260) taille=48×56
  - Aucun sprite joueur superposé (le personnage est déjà dessiné dans l'image)
  - Slot vide : fond totalement transparent (0,0,0,0) — le cadre dessiné est visible
  - Slot équipé : fond vert semi-transparent + bordure verte + icône via `ItemData` (padding 1 px)
  - Cliquer un slot équipé → déséquipe l'item
- **Zone items** (section droite, `ScrollContainer`) :
  - Grille **4 colonnes** de boutons 68×68 px (ITEMS_X=316, ITEMS_Y=56, ITEMS_W=288, ITEMS_H=280)
  - Icône grande (2 px de marge, 64×52 px effective) + nom tronqué sur 11 px en bas
  - Filtre automatique : seuls les items de `Inventory.items` présents dans `Stats.equipment_data`
  - Chaque bouton : icône + nom + badge ✓ si équipé, quantité si > 1
  - Cliquer → équipe ou déséquipe
- **Barre de détails** (36 px sous l'image) : texte dynamique au survol — bonus formatés `[+X FOR, +Y DEF…]`
- Se synchronise avec `Inventory.inventory_changed` — `_refresh()` appelé aussi depuis `hud.gd._on_inventory_changed()`
- `Stats.emit_signal("stats_changed")` déclenché à chaque équipement/déséquipement
- Palette de couleurs issue de `Equipment.png` : brun `(130,92,47)`, beige `(229,214,161)`, teal `(80,169,120)`, etc.

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
 