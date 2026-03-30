# 📋 Récapitulatif du projet — testJeu2D

> Godot 4.6 — Jeu 2D RPG (top-down)
> Dernière mise à jour : 2026-03-30

---

## 🗂️ Structure du projet

```
test-jeu-2d/
├── project.godot
├── scenes/
│   ├── world.tscn                  ← scène principale du jeu
│   ├── main_menu.tscn              ← menu principal
│   ├── player.tscn                 ← personnage joueur
│   ├── npc.tscn                    ← PNJ donneur de quêtes
│   ├── enemySlime.tscn             ← ennemi Slime
│   ├── enemySkeleton.tscn          ← ennemi Squelette
│   ├── chest.tscn                  ← coffre interactif
│   ├── item.tscn                   ← objet ramassable
│   ├── mouton.tscn                 ← animal (mouton)
│   ├── vache.tscn                  ← animal (vache)
│   ├── rock.tscn                   ← ressource (minerai)
│   ├── tree.tscn                   ← ressource (bois)
│   └── procedural_map_2d.tscn      ← carte générée procéduralement
├── scripts/
│   ├── player.gd
│   ├── enemy.gd
│   ├── npc.gd
│   ├── animal.gd
│   ├── chest.gd
│   ├── item.gd
│   ├── resource.gd
│   ├── projectile.gd               ← projectiles (flèche / sort)
│   ├── hud.gd
│   ├── crafting_panel.gd
│   ├── health_bar.gd               ← ⚠️ obsolète (voir section bugs)
│   ├── main_menu.gd
│   ├── procedural_map_2d.gd
│   ├── game_manager.gd             ← Autoload
│   ├── inventory.gd                ← Autoload
│   ├── quest_manager.gd            ← Autoload
│   └── stats.gd                    ← Autoload
└── assets/
    ├── Player/
    │   └── Player_bow_attack.png   ← spritesheet attaque arc (6 frames 32×32)
    ├── sprites/
    ├── menus/
    │   └── character_panel.png     ← HUD barres de vie/mana/xp
    ├── rpgItems.png                ← spritesheet items 16×16 (8×8 tuiles)
    └── itemset0.png                ← spritesheet items 16×16 (16×11 tuiles)
```

**Autoloads enregistrés :**
- `GameManager` — gestion de la sauvegarde, position de spawn, état des coffres
- `Inventory` — inventaire, or, outils, équipements
- `QuestManager` — quêtes actives/complètes, progression
- `Stats` — niveau, XP, statistiques de personnage, mana, données d'équipements

**Touches configurées :**
| Action | Touche |
|---|---|
| Déplacement | Flèches directionnelles |
| Attaque | Espace |
| Changer d'arme | Q |
| Interagir | E |
| Ouvrir crafting | B |
| Panneau personnage / Journal | C |
| Sauvegarder | S |
| Fermer menu | Échap |

---

## ✅ Fonctionnalités implémentées

### 🎮 Joueur
- Déplacement en 4 directions avec animations (marche, idle, attaque, outils)
- Système de vie avec signal `health_changed`
- Dégâts réduits par la défense : `dégâts reçus = max(1, dégâts - Stats.get_defense())`
- Attaque au corps à corps avec zone de collision directionnelle (`AttackZone`)
- **Attaque à distance — Arc** : animation de tir dédiée (spritesheet `Player_bow_attack.png`, 6 frames, ajoutée dynamiquement au runtime), puis spawn d'une flèche
- **Attaque à distance — Bâton magique** : consomme de la mana, spawn d'un projectile de sort
- Portée des projectiles calculée selon les stats (Arc : Force+Agilité ; Magie : stat Magie)
- **Changement d'arme** via touche Q : cycle parmi les armes possédées uniquement
- Invincibilité pendant l'attaque
- Utilisation d'outils orientés (hache, pioche) avec animations dédiées
- Guérison via potions (+30 PV) et viande (+15 PV)
- Respawn à la position sauvegardée au démarrage
- `max_health` synchronisé avec `Stats.get_max_health()` au démarrage

### 🏹 Projectiles
- Script `projectile.gd` commun pour flèche et sort
- Propriétés configurables : `proj_type`, `direction`, `max_range`, `damage`
- Déplacement en ligne droite, disparition au-delà de la portée max
- Détection de collision via `PhysicsShapeQueryParameters2D` (scan de zone, pas de corps physique)
- Spawn avec décalage vertical (-14 px) pour aligner visuellement sur le personnage

### 🗺️ Monde
- Génération procédurale de carte 2D (80×80 tuiles) avec seed
- 4 biomes : EAU, SABLE, FORÊT, ROCHE
- Transitions automatiques entre biomes via `set_cells_terrain_connect`
- Logique de placement de villages (positions calculées, instances commentées)

### 👾 Ennemis
- Patrouille automatique autour d'un point de départ
- Détection du joueur dans un rayon configurable → poursuite
- Dégâts continus au contact (damage per second)
- Système de vie + animation `hurt` (gardée jusqu'à la fin, non interrompue par le mouvement)
- Animation de mort + respawn automatique après délai configurable
- Récompense en XP à la mort
- Mise à jour des quêtes de type "kill" à la mort
- Deux types disponibles : Slime, Squelette (configurés via `@export enemy_type`)

### 🌿 Ressources & Animaux
- Arbres et rochers avec système de coups nécessaires (`health`)
- Vérification de l'outil requis avant récolte (hache pour bois, pioche pour minerai)
- Animation de "hit" au contact
- Récolte automatique quand `health <= 0` → ajout à l'inventaire
- Mise à jour des quêtes de type "collect"
- Respawn optionnel des ressources
- Animaux (mouton, vache) qui fuient le joueur dans un rayon configurable
- Chaque animal donne **deux drops** à la mort : viande (`resource_name`) + peau (`resource_name2`)
- Les deux drops sont configurables par export dans la scène de l'animal

### 📦 Inventaire
- Stockage d'objets avec quantités (dictionnaire)
- Or (gold) avec ajout/soustraction
- Outil équipé (hache / pioche / aucun)
- Slots d'équipement : arme, casque, plastron, bottes, anneau, amulette
- Signal `inventory_changed` pour mettre à jour l'UI
- Utilisation d'items depuis l'UI (potions, viande → soin ; équipements → équipement)
- Déséquipement depuis le panneau personnage
- Icônes pixel-art pour tous les items (armes, consommables, ressources)

### 📊 Statistiques, Mana & Progression
- 5 statistiques : Force, Endurance, Agilité, Magie, Défense
- Calcul des stats totales = base + bonus équipements
- Formules dérivées : vie max, dégâts, vitesse de déplacement, portée des projectiles
- **Système de mana** : `current_mana`, régénération automatique (`get_mana_regen()` mana/s)
- Coût par attaque magique = `max(5, 20 - Magie)` ; refus si mana insuffisante
- Signaux : `mana_changed(current, max)`, `stats_changed`, `level_up(new_level)`
- Système de niveaux et XP avec montée en niveau automatique
- 3 points à distribuer par niveau
- 10 équipements définis dans `Stats.equipment_data` avec leurs bonus

### 📜 Quêtes
- Deux quêtes implémentées : "Chasseur de slimes" (tuer 5 slimes) et "Bûcheron débutant" (récolter 10 bois)
- Système de quêtes actives / complètes / récompenses réclamées
- Démarrage de quête via interaction avec un PNJ
- Icône de quête au-dessus du PNJ (jaune = disponible, blanc = en cours, vert = récompense disponible)
- Réclamation de récompense via interaction une fois la quête terminée
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
- **Barre de vie** (rouge) — utilise les rangées rouges du spritesheet `character_panel.png`
- **Barre de mana** (bleue) — superposée sur le même sprite, rangées bleues ; se met à jour via signal `mana_changed`
- **Barre d'XP** (verte) — rangées vertes du même sprite ; se met à jour via signal `stats_changed`
- Les trois barres partagent la même texture source et s'affichent naturellement à des hauteurs différentes
- **Outil équipé** — icône pixel-art affichée dans un slot sous les barres, visible uniquement si un outil est équipé ; icônes : hache (`Rect2(64,80,16,16)`) et pioche (`Rect2(80,48,16,16)`) de `rpgItems.png`
- **Système de notifications** — panneau semi-transparent centré en haut, glisse depuis le haut, reste 2,2 s puis s'efface ; couleur configurable ; remplace immédiatement la notification précédente
  - Mauvais outil → notification orange "Il vous faut une hache 🪓 !"
  - Level up → notification dorée "🎉 Niveau X ! +3 points à distribuer"
- Panneau inventaire (grille d'items avec icônes sprites, or)
- Panneau personnage (stats colorées, boutons "+" pour dépenser les points)
- Panneau équipements (6 slots avec déséquipement au clic)
- Journal de quêtes avec progression
- Boîte de dialogue pour les PNJ
- Boutons HUD : Inventaire, Personnage, Quêtes

### 🔨 Système de Crafting
- Touche **B** : ouvre/ferme le panneau de crafting
- Deux onglets **Armes** / **Potions** : boutons invisibles positionnés sur les icônes du spritesheet
- Zone gauche : liste des recettes sous forme d'icônes carrées (grille 3 colonnes)
- Zone droite : ingrédients requis (icône + quantité verte/rouge) et objet résultant
- Bouton CRÉER transparent superposé sur le sprite CREATE
- Message de confirmation (2,5 s) après fabrication

**Recettes implémentées :**
| Recette | Ingrédients | Résultat |
|---|---|---|
| Épée en bois | 2 Bois | Epee en bois |
| Épée en fer | 3 Minerai | Epee en fer |
| Potion | 1 Plante | Potion |

**Ajouter une recette** dans `scripts/crafting_panel.gd`, section `RECIPES` :
```gdscript
const RECIPES = {
    "armes": [
        {"name": "Epee en bois", "ingredients": {"Bois": 2},    "result": "Epee en bois", "result_qty": 1},
        # ajouter ici...
    ],
    "potions": [
        {"name": "Potion",       "ingredients": {"Plante": 1},  "result": "Potion",       "result_qty": 1},
    ],
}
```

### 💾 Sauvegarde / Chargement
- Sauvegarde JSON dans `user://save.json`
- Données sauvegardées : position, vie, inventaire, or, outil, coffres ouverts, stats, équipements, **niveau et XP**
- Compatibilité avec anciennes sauvegardes (vérification des clés)
- Chargement au menu principal via "Continuer" → restaure le niveau correctement
- Bouton "Continuer" désactivé si aucune sauvegarde

### 🎨 Menu Principal
- Boutons : Nouvelle Partie, Continuer, Quitter
- "Nouvelle Partie" réinitialise l'intégralité de l'état : GameManager, Inventory, QuestManager, Stats, mana
- "Continuer" désactivé si pas de sauvegarde
- "Quitter" ferme l'application

---

## ✅ Aucun bug ou code obsolète connu

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

## 🔭 Pistes d'évolution possibles

- ~~Système de crafting~~ ✅ implémenté
- ~~Attaques à distance (arc, magie)~~ ✅ implémenté
- ~~Système de mana~~ ✅ implémenté
- ~~Barre d'XP sur le HUD~~ ✅ implémenté
- ~~Affichage de l'outil équipé sur le HUD~~ ✅ implémenté
- ~~Notifications in-game~~ ✅ implémenté
- Ajouter d'autres recettes de crafting (Arc, Bâton magique, Casque…)
- Potion de mana (régénération instantanée de mana)
- Ajouter d'autres quêtes dans `QuestManager.QUESTS`
- Sons et musique (effets d'attaque, ambiance, musique de fond)
- Système de dialogues plus élaboré (plusieurs lignes, choix de réponse)
- Ennemis supplémentaires avec comportements différents (rôdeur à distance, boss)
- Plusieurs zones/scènes avec transitions
- Minimap
