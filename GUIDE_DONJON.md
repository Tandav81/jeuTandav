# 🏰 Guide — Ajout du Donjon + Cinématique

## Vue d'ensemble du système

```
world.tscn
  ├── Portal (entrée donjon)            → dungeon.tscn
  ├── LockedPortal (entrée secrète)     → récompense (zone secrète, trésor…)
  │     ↑ s'ouvre via cinématique après mort du boss
  ├── DungeonCinematic (Node)           ← gère la cinématique d'ouverture
  └── BossRoomGate (StaticBody2D)       ← bloque l'accès avant mort du boss (optionnel)

dungeon.tscn
  ├── Boss (is_boss=true, cinematic_key="Clé du donjon", unique_drops=[{name:"Clé du donjon"}])
  └── Portal (sortie)                   → world.tscn
```

La clé de liaison entre les trois éléments est une chaîne de texte identique :
- `cinematic_key` sur le boss
- `required_key` sur le LockedPortal
- `watched_key` sur le nœud DungeonCinematic

---

## ÉTAPE 1 — Créer dungeon.tscn

1. **Dupliquer `cave.tscn`** : clic-droit dans le FileSystem → Duplicate → `dungeon.tscn`
2. Ouvrir `dungeon.tscn`
3. **Adapter le TileMap** si tu veux un look différent de la grotte (optionnel)
4. **Supprimer** les spawners cave si tu veux un donjon plus statique

---

## ÉTAPE 2 — Placer le boss dans dungeon.tscn

1. Dans `dungeon.tscn` : **Instancier une scène enfant** → `minotaur.tscn` (ou golem, ou autre)
2. Sélectionner le nœud boss → **Inspecteur** :
   - `is_boss` → ✅ cocher
   - `boss_name` → `"Gardien du donjon"` (ou ce que tu veux)
   - `cinematic_key` → `"Clé du donjon"` ← **IMPORTANT — doit correspondre aux étapes 4 et 5**
   - `respawn_once` → ✅ cocher (le boss ne réapparaît pas après la première mort)
   - `unique_drops` → cliquer `+ Add Element` :
     - `name` : `"Clé du donjon"`
     - `qty` : `1`
3. Positionner le boss dans le donjon

---

## ÉTAPE 3 — Portail de sortie dans dungeon.tscn

1. Instancier `portal.tscn` dans `dungeon.tscn`
2. Inspecteur du portail :
   - `target_scene` → `"res://scenes/world.tscn"`
   - `target_spawn` → coordonnées de spawn dans world.tscn (ex: `Vector2(300, 400)`)
   - `portal_label` → `"Retour au monde"`
   - `ambient_music` → stream audio du monde extérieur (optionnel)

---

## ÉTAPE 4 — Portail d'entrée dans world.tscn

1. Ouvrir `world.tscn`
2. Instancier `portal.tscn` à l'endroit où tu veux l'entrée du donjon
3. Inspecteur :
   - `target_scene` → `"res://scenes/dungeon.tscn"`
   - `target_spawn` → coordonnées d'apparition dans le donjon (ex: `Vector2(100, 100)`)
   - `portal_label` → `"Entrée du donjon"`
   - `ambient_music` → stream audio du donjon (optionnel)

---

## ÉTAPE 5 — Portail verrouillé dans world.tscn (cible de la cinématique)

> Ce portail est la récompense : il mène vers une zone secrète, une salle au trésor, etc.

1. Dans `world.tscn` : **Créer un nouveau nœud** de type `Area2D`
2. Renommer en `LockedPortal`
3. Ajouter comme enfants :
   - `CollisionShape2D` (avec une shape, ex: `RectangleShape2D` 32×32)
   - `Label` (renommer en `Label`, texte = `"🔒 Entrée secrète"`)
4. Dans l'Inspecteur → **Script** → assigner `res://scripts/locked_portal.gd`
5. Configurer les exports :
   - `target_scene` → scène de destination (ex: `"res://scenes/cave.tscn"` ou une nouvelle scène)
   - `target_spawn` → position de spawn
   - `portal_label` → `"🔒 Entrée secrète"`
   - `required_key` → `"Clé du donjon"` ← doit correspondre **exactement** à `cinematic_key` du boss
   - `required_quest` → laisser vide (ou mettre un ID de quête si tu veux conditionner aussi à une quête)
   - `ambient_music` → stream audio de la zone secrète (optionnel)

---

## ÉTAPE 6 — Ajouter DungeonCinematic dans world.tscn

1. Dans `world.tscn` : **Créer un nœud** de type `Node`
2. Renommer en `DungeonCinematic`
3. **Script** → `res://scripts/dungeon_cinematic.gd`
4. Inspecteur :
   - `watched_key` → `"Clé du donjon"` ← doit correspondre à `cinematic_key` et `required_key`
   - `cinematic_zoom` → `2.0` (ajustable)
   - `pan_duration` → `1.5`
   - `hold_duration` → `2.0`
   - `return_duration` → `1.2`
   - `debug_mode` → activer pour voir les logs en console si la cinématique ne se déclenche pas

> 💡 Pour plusieurs boss/donjons : dupliquer autant de nœuds `DungeonCinematic`, chacun avec son propre `watched_key`.

---

## ÉTAPE 7 — (Optionnel) Barrière de salle de boss

1. Dans `dungeon.tscn` : **Créer un nœud** `StaticBody2D` à l'entrée de la salle du boss
2. Ajouter un `CollisionShape2D` enfant (couvrant le passage)
3. Ajouter un `Sprite2D` enfant pour le visuel (barrière, grille, etc.)
4. **Script** → `res://scripts/boss_room_gate.gd`
5. Inspecteur :
   - `boss_node_path` → sélectionner le nœud boss (via l'icône NodePath)
   - `fade_duration` → `0.8` (ajustable)

La barrière disparaît automatiquement à la mort du boss.

---

## ÉTAPE 8 — Enregistrer AudioManager comme Autoload

> À faire **une seule fois** si ce n'est pas encore fait.

1. **Project → Project Settings → Autoload**
2. Cliquer `+` :
   - Chemin : `res://scripts/audio_manager.gd`
   - Nom : `AudioManager`
3. Valider

Sans cette étape, les portails avec `ambient_music` lèveront une erreur.

---

## Résumé du flow final

1. Joueur entre dans le donjon (portail normal)
2. Tue le boss → `"Clé du donjon"` ajoutée à l'inventaire + `pending_cinematics` mis à jour
3. Joueur ressort via le portail de sortie → retour dans `world.tscn`
4. **Cinématique automatique** :
   - Notification dorée : *"✨ Une entrée secrète vient de s'ouvrir !"*
   - Caméra pan + zoom vers le `LockedPortal`
   - Flash doré sur le portail → il s'ouvre (passe de bleuté à blanc)
   - Caméra revient au joueur
   - Joueur reprend le contrôle
5. Le `LockedPortal` est maintenant actif → le joueur peut le traverser

---

## Dépannage

| Symptôme | Cause probable | Solution |
|---|---|---|
| Cinématique ne se déclenche pas | `watched_key` ne correspond pas à `cinematic_key` | Vérifier que les 3 chaînes sont identiques |
| Cinématique se déclenche mais ne va nulle part | Aucun `LockedPortal` dans le groupe | Vérifier que `add_to_group("locked_portal")` est appelé dans `locked_portal.gd` |
| Portail reste verrouillé | Item dans l'inventaire mais `required_key` incorrect | Vérifier l'orthographe exacte (sensible à la casse) |
| Erreur `AudioManager` | Autoload non enregistré | Suivre l'étape 8 |
| Cinématique ne se déclenche pas après rechargement du jeu | `pending_cinematics` non persisté | Vérifier `game_manager.gd` → `save_data` et `load_game` |

### Tester manuellement la cinématique

Depuis la console Godot (pendant l'exécution) :
```gdscript
get_tree().get_first_node_in_group("dungeon_cinematic").play_cinematic()
```

Ou pour forcer l'ajout d'une clé sans tuer le boss :
```gdscript
GameManager.pending_cinematics.append("Clé du donjon")
get_tree().reload_current_scene()
```
