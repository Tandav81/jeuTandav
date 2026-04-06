# 🏰 Guide — Ajout du Donjon + Cinématique

## Vue d'ensemble du système

```
world.tscn
  ├── Portal (entrée donjon)          → dungeon.tscn
  └── LockedPortal (entrée secrète)   → rewards.tscn (ou autre zone)
        ↑ s'ouvre via cinématique après mort du boss

dungeon.tscn
  ├── Boss (is_boss=true, triggers_world_cinematic=true, unique_drops=[{name:"Clé du donjon"}])
  └── Portal (sortie)                 → world.tscn
```

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
   - `triggers_world_cinematic` → ✅ cocher ← **IMPORTANT pour la cinématique**
   - `unique_drops` → cliquer `+ Add Element` :
     - `name` : `"Clé du donjon"`
     - `qty` : `1`
   - `respawn_time` → `999` (ou très grand pour qu'il ne respawn pas)
3. Positionner le boss dans le donjon

---

## ÉTAPE 3 — Portail de sortie dans dungeon.tscn

1. Instancier `portal.tscn` dans `dungeon.tscn`
2. Inspecteur du portail :
   - `target_scene` → `"res://scenes/world.tscn"`
   - `target_spawn` → coordonnées de spawn dans world.tscn (ex: `Vector2(300, 400)`)
   - `portal_label` → `"Retour au monde"`

---

## ÉTAPE 4 — Portail d'entrée dans world.tscn

1. Ouvrir `world.tscn`
2. Instancier `portal.tscn` à l'endroit où tu veux l'entrée du donjon
3. Inspecteur :
   - `target_scene` → `"res://scenes/dungeon.tscn"`
   - `target_spawn` → coordonnées d'apparition dans le donjon (ex: `Vector2(100, 100)`)
   - `portal_label` → `"Entrée du donjon"`

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
   - `required_key` → `"Clé du donjon"` ← doit correspondre exactement au nom dans `unique_drops`
6. **Noter la position du nœud LockedPortal** (tu en auras besoin à l'étape 6)

---

## ÉTAPE 6 — Ajouter DungeonCinematic dans world.tscn

1. Dans `world.tscn` : **Créer un nœud** de type `Node`
2. Renommer en `DungeonCinematic`
3. **Script** → `res://scripts/dungeon_cinematic.gd`
4. Inspecteur :
   - `locked_portal_path` → **cliquer l'icône de sélection de nœud** → sélectionner le `LockedPortal` ajouté à l'étape 5
   - `cinematic_zoom` → `2.0` (ajustable)
   - `pan_duration` → `1.5`
   - `hold_duration` → `2.0`
   - `return_duration` → `1.2`

---

## Résumé du flow final

1. Joueur entre dans le donjon (portail normal)
2. Tue le boss → `"Clé du donjon"` ajoutée à l'inventaire automatiquement
3. Joueur ressort via le portail de sortie → retour dans `world.tscn`
4. **Cinématique automatique** :
   - Notification dorée : *"✨ Une entrée secrète vient de s'ouvrir !"*
   - Caméra pan + zoom vers le `LockedPortal`
   - Flash doré sur le portail → il s'ouvre (passe de bleuté à blanc)
   - Caméra revient au joueur
   - Joueur reprend le contrôle
5. Le `LockedPortal` est maintenant actif → le joueur peut le traverser

---

## Notes

- Le `LockedPortal` reste ouvert après la cinématique, même après rechargement de la scène
  (car `_check_open_state()` vérifie l'inventaire au `_ready`)
- Pour tester la cinématique sans tuer le boss : dans le script `dungeon_cinematic.gd`,
  appeler `$DungeonCinematic.play_cinematic()` depuis la console Godot
- L'item `"Clé du donjon"` doit correspondre **exactement** entre `unique_drops` du boss et `required_key` du portail
