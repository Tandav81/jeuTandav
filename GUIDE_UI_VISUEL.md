# Guide pas à pas : Améliorer le rendu visuel du HUD avec tes spritesheets

Ce guide t'explique comment remplacer les éléments visuels génériques de ton HUD par les spritesheets que tu as dans `assets/menus/`. Chaque section est indépendante, tu peux les faire dans l'ordre que tu veux.

---

## Prérequis important : Import des textures en Pixel Art

Avant de commencer, assure-toi que tes textures sont importées correctement pour du pixel art (sinon elles seront floues quand elles seront agrandies).

1. Dans Godot, sélectionne **toutes les images** dans `assets/menus/` (clic sur la première, Shift+clic sur la dernière dans le FileSystem)
2. Va dans l'onglet **Import** (à côté de Scene en haut à gauche)
3. Change **Filter** → décocher `Filter` (ou mettre "Nearest" si c'est un menu déroulant)
4. Clique **Reimport**
5. Fais pareil pour les images dans `assets/healthbar/` et `assets/UI/`

> **Pourquoi ?** Sans ça, Godot applique un filtre bilinéaire qui rend les pixels flous quand ils sont agrandis.

---

## Partie 1 : La Barre de Vie (TextureProgressBar avec character_panel.png)

Ta barre de vie actuelle utilise les petites images `healthbarUnder.png` et `healthbarProgress.png` avec un scale x3. On va la remplacer par les belles barres style RPG de `character_panel.png` qui ont un portrait de personnage intégré.

### Comprendre le spritesheet character_panel.png (192x160)

Ce spritesheet contient des barres de vie/mana stylisées. Voici les régions utiles :

| Élément | Position (x, y, largeur, hauteur) | Description |
|---------|-----------------------------------|-------------|
| Barre fond + portrait | (1, 2, 89, 36) | Barre brune vide avec portrait du personnage |
| Barre remplie + portrait | (97, 2, 85, 36) | Barre arc-en-ciel remplie avec portrait |
| Barre fond sans portrait | (1, 42, 89, 36) | Barre brune vide (sans portrait) |
| Barre remplie sans portrait | (97, 42, 85, 36) | Barre colorée remplie (sans portrait) |
| Petite barre fine | (4, 120, 75, 8) | Barres fines pour XP ou mana |

### Étape 1.1 : Extraire les textures de la barre

Tu as deux options pour utiliser ces barres :

**Option A — AtlasTexture dans l'éditeur (recommandé) :**

1. Sélectionne le noeud `HUD > HealthBar` (TextureProgressBar) dans world.tscn
2. Dans l'Inspector, pour **Texture Under** :
   - Clique sur la valeur actuelle → `New AtlasTexture`
   - Dans l'AtlasTexture, charge `Atlas` → `res://assets/menus/character_panel.png`
   - Règle `Region` → `x: 1, y: 2, w: 89, h: 36`
   - Cela donne la barre brune vide avec le portrait
3. Pour **Texture Progress** :
   - Clique → `New AtlasTexture`
   - `Atlas` → `res://assets/menus/character_panel.png`
   - `Region` → `x: 97, y: 2, w: 85, h: 36`
   - Cela donne la barre colorée (remplie)

**Option B — Extraire les images séparément :**

Si l'AtlasTexture ne rend pas bien (décalage de pixels), tu peux extraire les images avec un éditeur d'image (GIMP, Aseprite, Paint.NET) :
- Ouvre `character_panel.png`
- Sélectionne la zone (1, 2) à (90, 38) → exporte en `hp_bar_under.png`
- Sélectionne la zone (97, 2) à (182, 38) → exporte en `hp_bar_progress.png`
- Place-les dans `assets/healthbar/` et utilise-les directement

### Étape 1.2 : Ajuster la HealthBar dans la scène

1. Sélectionne `HUD > HealthBar`
2. Change les propriétés :
   - **Scale** → `Vector2(2, 2)` ou `Vector2(3, 3)` selon la taille souhaitée (teste !)
   - **Position** → Ajuste pour que la barre soit en haut à gauche (ex: `x: 10, y: 10`)
   - **Fill Mode** → Laisse `Left to Right` (valeur 0)
   - **Value** → 100 (pour tester)
3. **Problème potentiel** : Si la barre remplie et la barre vide n'ont pas exactement la même taille, il faudra ajuster l'offset de la texture progress via `Texture Progress Offset` dans l'Inspector

### Étape 1.3 : Gérer le décalage portrait/barre

La barre avec portrait a le portrait à gauche (environ 24px) et la barre réelle commence après. La texture progress doit être calée sur la partie "barre" uniquement. Si le remplissage ne s'aligne pas bien :

1. Dans l'Inspector de HealthBar, cherche **Texture Progress Offset**
2. Ajuste `x` vers la droite (essaie `x: 4, y: 0`) jusqu'à ce que le remplissage s'aligne avec le fond

> **Alternative simple** : Utilise les barres **sans portrait** (ligne 2 du spritesheet : y=42) et ajoute le portrait séparément comme un TextureRect par-dessus. C'est plus facile à aligner.

---

## Partie 2 : Le Panneau Inventaire

Ton inventaire utilise actuellement `freefantasy.png` comme StyleBoxTexture. On va le remplacer par le panneau de `Inventory.png` qui est beaucoup plus beau.

### Comprendre Inventory.png (336x160)

| Élément | Région (x, y, w, h) | Description |
|---------|---------------------|-------------|
| Panneau complet avec grille | (192, 0, 144, 112) | Panel assemblé avec titre "INVENTORY" et grille 5x4 |
| Petit panneau vide | (8, 0, 80, 96) | Panneau vide utilisable pour des sous-panneaux |
| Panneau avec grille (sans titre) | (96, 0, 80, 96) | Panneau avec slots de grille |
| Barre de titre | (80, 112, 112, 16) | Barre "INVENTORY" seule |
| Icônes d'items | (176, 112, 160, 48) | Petites icônes d'items (épées, potions, etc.) |

### Étape 2.1 : Changer le fond du PanneauInventaire

**Méthode avec StyleBoxTexture (ce que tu fais déjà, mais avec la nouvelle image) :**

1. Sélectionne `HUD > PanneauInventaire` dans l'arbre de scène
2. Dans l'Inspector → `Theme Overrides > Styles > Panel`
3. Clique sur le StyleBoxTexture existant (freefantasy.png)
4. Change **Texture** → charge `res://assets/menus/Inventory.png`
5. Règle **Region** → `Enabled: true`, puis `Rect: x: 8, y: 0, w: 80, h: 96`
   (cela prend le petit panneau vide qui peut être étiré)
6. Règle les **marges du 9-slice** (c'est la clé pour un bon rendu !) :
   - **Margin Left** : `8`
   - **Margin Top** : `12`
   - **Margin Right** : `8`
   - **Margin Bottom** : `8`
   - **Axis Stretch Horizontal** : `Tile`
   - **Axis Stretch Vertical** : `Tile`

> **Qu'est-ce que le 9-slice ?** Le 9-slice découpe la texture en 9 zones (coins + bords + centre). Les coins restent fixes, les bords sont étirés/tuilés, et le centre remplit le reste. Cela permet de redimensionner le panneau sans déformer les coins.

### Étape 2.2 : Alternative avec NinePatchRect (meilleur contrôle)

Si le StyleBoxTexture ne donne pas un bon résultat, tu peux remplacer le Panel par un NinePatchRect :

1. Dans l'arbre de scène, ajoute un **NinePatchRect** comme enfant du HUD
2. Nomme-le `PanneauInventaireBG`
3. Place-le **juste avant** PanneauInventaire (ou reparente les enfants)
4. Dans l'Inspector :
   - **Texture** → `res://assets/menus/Inventory.png`
   - **Region** → cocher `Region Enabled`, puis `Rect: x: 8, y: 0, w: 80, h: 96`
   - **Patch Margin Left** : `8`
   - **Patch Margin Top** : `12`
   - **Patch Margin Right** : `8`
   - **Patch Margin Bottom** : `8`
5. Redimensionne-le à la même taille que ton PanneauInventaire
6. Sur le PanneauInventaire lui-même, rends le fond transparent :
   - `Theme Overrides > Styles > Panel` → `New StyleBoxEmpty`

### Étape 2.3 : Ajouter le titre "INVENTAIRE" avec style

Plutôt que d'utiliser un Label texte, tu peux utiliser la barre de titre du spritesheet :

1. Ajoute un **TextureRect** comme premier enfant de PanneauInventaire
2. Texture → `New AtlasTexture` :
   - Atlas : `res://assets/menus/Inventory.png`
   - Region : `x: 192, y: 0, w: 144, h: 16` (la barre de titre verte avec "INVENTORY")
3. **Stretch Mode** → `Keep Aspect Centered`
4. Positionne-le en haut du panneau

> **Note** : Le texte dit "INVENTORY" en anglais. Si tu veux "INVENTAIRE", garde plutôt un Label par-dessus la barre verte, avec une police pixel art.

### Étape 2.4 : Améliorer les slots d'items dans le code (hud.gd)

Actuellement tes slots sont des `PanelContainer` avec un `StyleBoxFlat` brun. Pour utiliser les tuiles du spritesheet :

Dans `hud.gd`, modifie la fonction `_refresh_inventaire()`. Remplace le bloc de création du style :

```gdscript
# AVANT (StyleBoxFlat)
var style = StyleBoxFlat.new()
style.bg_color = Color("#a07850")
# ...

# APRÈS (StyleBoxTexture avec le spritesheet)
var style = StyleBoxTexture.new()
style.texture = load("res://assets/menus/Inventory.png")
style.region_rect = Rect2(264, 16, 16, 16)  # un slot individuel de la grille
style.texture_margin_left = 2
style.texture_margin_right = 2
style.texture_margin_top = 2
style.texture_margin_bottom = 2
```

Les coordonnées `(264, 16, 16, 16)` pointent vers une cellule vide de la grille dans le panneau assemblé. Ajuste selon le rendu (la grille commence environ à x=200, y=16 dans le panneau complet).

> **Astuce** : Tu peux aussi utiliser `Main_tiles.png` qui contient des tuiles de panneau individuelles plus faciles à utiliser pour les slots. Les petits carrés beiges à la ligne 4 (environ y=192, taille 16x16) sont parfaits.

---

## Partie 3 : Le Panneau Personnage (Stats + Équipement)

### Comprendre Equipment.png (160x384)

| Élément | Région (x, y, w, h) | Description |
|---------|---------------------|-------------|
| Panneau mannequin (gauche) | (0, 256, 80, 96) | Zone avec silhouette pour équipement |
| Panneau grille équipement | (80, 256, 80, 96) | Grille de slots + titre "EQUIPMENT" |
| Barre titre "EQUIPMENT" | (80, 256, 80, 16) | Barre de titre verte |
| Icônes équipement | (0, 352, 160, 32) | Mannequin + icônes individuelles |

### Étape 3.1 : Fond du PanneauPersonnage principal

Le PanneauPersonnage utilise actuellement un StyleBoxFlat. Remplace-le :

1. Sélectionne `HUD > PanneauPersonnage`
2. Inspector → `Theme Overrides > Styles > Panel`
3. Change en `New StyleBoxTexture`
4. Texture → `res://assets/menus/Inventory.png`
5. Region Rect → `x: 8, y: 0, w: 80, h: 96` (même panneau vide que l'inventaire pour la cohérence)
6. Marges 9-slice : Left=8, Top=12, Right=8, Bottom=8
7. Axis Stretch → `Tile`

### Étape 3.2 : Fond des sous-panneaux Stats et Équipement

Pour PanneauStats et PanneauEquipement (les deux sous-panneaux côte à côte) :

1. Sélectionne `HUD > PanneauPersonnage > HBoxContainer > PanneauStats`
2. Inspector → `Theme Overrides > Styles > Panel` → `New StyleBoxTexture`
3. Utilise le même principe mais avec une teinte plus sombre :
   - Texture → `res://assets/menus/Main_tiles.png`
   - Region → Cherche un des petits panneaux sombres dans Main_tiles (environ `x: 0, y: 192, w: 32, h: 32`)
   - Marges 9-slice : Left=4, Top=4, Right=4, Bottom=4
   - Axis Stretch → `Tile`
4. Répète pour PanneauEquipement

### Étape 3.3 : Utiliser l'image du mannequin d'Equipment.png

Pour rendre le panneau d'équipement plus visuel :

1. Ajoute un **TextureRect** dans PanneauEquipement, nommé `MannequinBG`
2. Texture → `New AtlasTexture` :
   - Atlas : `res://assets/menus/Equipment.png`
   - Region : `x: 0, y: 272, w: 64, h: 64` (la silhouette du mannequin)
3. Place-le en arrière-plan derrière les slots d'équipement
4. **Modulate** → Réduis l'opacité (`Color(1, 1, 1, 0.3)`) pour qu'il soit subtil en fond
5. Les 6 slots d'équipement se superposent visuellement au mannequin

### Étape 3.4 : Améliorer les boutons + dans les stats (hud.gd)

Dans `_refresh_stats()`, remplace les `StyleBoxFlat` des boutons "+" par des textures du spritesheet Buttons.png :

```gdscript
# Pour les boutons "+" actifs, utilise un des petits boutons verts de Buttons.png
var style_actif = StyleBoxTexture.new()
style_actif.texture = load("res://assets/menus/Buttons.png")
# Petit bouton vert (environ 24x24) - première ligne de Buttons.png
style_actif.region_rect = Rect2(8, 16, 24, 24)
style_actif.texture_margin_left = 4
style_actif.texture_margin_right = 4
style_actif.texture_margin_top = 4
style_actif.texture_margin_bottom = 4
btn_plus.add_theme_stylebox_override("normal", style_actif)
```

> **Remarque** : Les boutons de `Buttons.png` sont sur une grille d'environ 24x24px. La première ligne contient des carrés verts de différentes tailles. Teste les régions pour trouver celui qui te plaît.

---

## Partie 4 : Le Journal de Quêtes (style Inventory)

Le QuestJournal est actuellement un Panel brut sans style. On va lui donner le même look que l'inventaire.

### Étape 4.1 : Appliquer le fond

1. Sélectionne `HUD > QuestJournal`
2. Inspector → `Theme Overrides > Styles > Panel` → `New StyleBoxTexture`
3. Texture → `res://assets/menus/Inventory.png`
4. Region → `Enabled: true`, `Rect: x: 8, y: 0, w: 80, h: 96`
5. Marges 9-slice : Left=8, Top=12, Right=8, Bottom=8
6. Axis Stretch → `Tile`

### Étape 4.2 : Ajouter un titre "QUÊTES"

1. Ajoute un **Label** en haut du QuestJournal (avant QuestList)
2. Texte : "QUÊTES"
3. Police : ta police pixel art
4. Couleur : `Color("#3d2b1f")` (brun foncé pour s'accorder avec le bois)
5. Taille : 16-18px
6. Alignement : Centré

Ou mieux, ajoute une barre de titre verte comme pour l'inventaire :
1. Ajoute un **TextureRect** en haut
2. AtlasTexture → `res://assets/menus/Inventory.png`, Region: `x: 192, y: 0, w: 144, h: 16`
3. Mets un Label "QUÊTES" par-dessus la barre

### Étape 4.3 : Améliorer l'affichage des quêtes dans le code (hud.gd)

Dans `update_quest_journal()`, ajoute un style aux labels de quêtes :

```gdscript
func update_quest_journal():
    for child in quest_liste.get_children():
        child.queue_free()

    for quest in QuestManager.active_quests:
        # Conteneur avec fond pour chaque quête
        var quest_panel = PanelContainer.new()
        var style = StyleBoxTexture.new()
        style.texture = load("res://assets/menus/Main_tiles.png")
        # Utilise une tuile de fond beige/parchemin
        style.region_rect = Rect2(160, 192, 32, 32)  # ajuste selon la tuile
        style.texture_margin_left = 4
        style.texture_margin_right = 4
        style.texture_margin_top = 4
        style.texture_margin_bottom = 4
        quest_panel.add_theme_stylebox_override("panel", style)

        var label = Label.new()
        var text = quest.name + "\n"
        text += quest.description + "\n"
        text += "Progression : %d / %d" % [quest.progress, quest.required]
        if quest.completed:
            text += "\n✅ Terminé - Retourner voir le PNJ"
        label.text = text
        label.autowrap_mode = TextServer.AUTOWRAP_WORD
        label.add_theme_color_override("font_color", Color("#3d2b1f"))
        label.add_theme_font_size_override("font_size", 14)

        quest_panel.add_child(label)
        quest_liste.add_child(quest_panel)
```

---

## Partie 5 : Les Boutons du HUD (Inventaire, Personnage, Quêtes)

Tes 3 boutons (🎒, ⚔️, 📜) utilisent des émojis et des StyleBoxFlat. On va les remplacer par de vrais boutons graphiques.

### Comprendre les assets disponibles

- `Buttons.png` (400x528) : contient plein de boutons avec texte anglais (INVENTORY, EQUIPMENT, SHOP, etc.) et des petits boutons carrés
- `Icons.png` (96x304) : contient des icônes 16x16 (épée, bouclier, potion, sac, etc.)

### Étape 5.1 : Utiliser les boutons labellisés de Buttons.png

Les boutons avec texte sont dans la partie basse de Buttons.png. Voici les régions approximatives pour les boutons qui t'intéressent (4 états : normal, hover, pressed, disabled) :

| Bouton | Normal | Hover | Pressed | Disabled |
|--------|--------|-------|---------|----------|
| INVENTORY | (0, 416, 96, 16) | (96, 416, 96, 16) | (192, 416, 96, 16) | (288, 416, 96, 16) |
| EQUIPMENT | (0, 432, 96, 16) | (96, 432, 96, 16) | (192, 432, 96, 16) | (288, 432, 96, 16) |

> **Attention** : Ces coordonnées sont approximatives ! Ouvre `Buttons.png` dans Godot ou un éditeur d'image et note les positions exactes des boutons INVENTORY et EQUIPMENT.

### Étape 5.2 : Configurer les boutons avec StyleBoxTexture

Pour chaque bouton (BtnInventaire, BtnPersonnage, BtnQuetes) :

1. Sélectionne le bouton dans l'arbre
2. Supprime le texte emoji (vide le champ `Text`)
3. Dans `Theme Overrides > Styles` :
   - **Normal** → `New StyleBoxTexture`
     - Texture : `res://assets/menus/Buttons.png`
     - Region : la position du bouton état "normal"
   - **Hover** → `New StyleBoxTexture`
     - Même texture, region de l'état "hover"
   - **Pressed** → `New StyleBoxTexture`
     - Même texture, region de l'état "pressed"
4. Ajuste la taille du bouton pour correspondre à la taille de la texture (× ton facteur de scale)

### Étape 5.3 : Alternative — Boutons carrés avec icônes

Si tu préfères des boutons carrés compacts avec des icônes (plus esthétique pour un HUD de jeu) :

1. Utilise les petits boutons carrés verts de `Buttons.png` (première ligne, ~24x24 chacun)
2. Ajoute un `TextureRect` comme enfant du bouton avec une icône de `Icons.png`
3. Icônes utiles dans `Icons.png` (grille 16x16, 6 colonnes) :
   - Sac/coffre (pour inventaire) : environ `x: 0, y: 16, w: 16, h: 16`
   - Épée (pour personnage) : environ `x: 80, y: 224, w: 16, h: 16`
   - Parchemin (pour quêtes) : environ `x: 48, y: 32, w: 16, h: 16`

```gdscript
# Exemple dans _ready() ou directement dans l'éditeur :
# Créer un bouton avec icône
var btn_texture = StyleBoxTexture.new()
btn_texture.texture = load("res://assets/menus/Buttons.png")
btn_texture.region_rect = Rect2(8, 16, 24, 24)  # petit bouton vert
$BtnInventaire.add_theme_stylebox_override("normal", btn_texture)

# Ajouter l'icône par-dessus
var icon = TextureRect.new()
var atlas = AtlasTexture.new()
atlas.atlas = load("res://assets/menus/Icons.png")
atlas.region = Rect2(0, 16, 16, 16)  # icône sac
icon.texture = atlas
icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH
icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
$BtnInventaire.add_child(icon)
```

---

## Partie 6 : La Boîte de Dialogue

La DialogueBox utilise un StyleBoxFlat simple. Améliore-la :

1. Sélectionne `HUD > DialogueBox`
2. `Theme Overrides > Styles > Panel` → `New StyleBoxTexture`
3. Texture → `res://assets/menus/Inventory.png`
4. Region → `x: 8, y: 0, w: 80, h: 96` (panneau bois)
5. Marges 9-slice : Left=8, Top=8, Right=8, Bottom=8
6. Axis Stretch → `Tile`

Ou utilise `Main_tiles.png` pour un panneau différent (plus sombre, style parchemin brun).

---

## Partie 7 : La Barre d'Action (Action_panel.png)

Si tu veux ajouter une barre d'action en bas de l'écran (avec les slots pour items rapides) :

`Action_panel.png` (192x96) contient une barre horizontale avec des emplacements carrés.

1. La barre complète est environ à : `x: 12, y: 13, w: 178, h: 19`
2. Les slots individuels (carrés bruns) : `x: 12, y: 48, w: 16, h: 16` (environ)
3. Les icônes d'éléments (feu, eau, etc.) sont en bas à droite

Pour l'intégrer :
1. Ajoute un **NinePatchRect** ou **TextureRect** en bas du HUD
2. Charge l'AtlasTexture de la barre d'action
3. Ajoute des boutons/slots par-dessus

---

## Résumé des coordonnées clés (référence rapide)

### character_panel.png (192x160)
```
Barre HP fond+portrait :    x=1,  y=2,   w=89, h=36
Barre HP remplie+portrait : x=97, y=2,   w=85, h=36
Barre fond sans portrait :  x=1,  y=42,  w=89, h=36
Barre remplie sans portrait:x=97, y=42,  w=85, h=36
Barre fond (3e variante):   x=1,  y=82,  w=89, h=36
Barre remplie (3e var):     x=97, y=82,  w=85, h=36
Petites barres fines :      x=4,  y=120, w=75, h=8
Portraits :                 x=88, y=130, w=50, h=28
```

### Inventory.png (336x160)
```
Petit panneau vide :        x=8,   y=0,   w=80,  h=96
Panneau avec grille :       x=96,  y=0,   w=80,  h=96
Panneau complet assemblé :  x=192, y=0,   w=144, h=112
Barre titre verte :         x=192, y=0,   w=144, h=16
Icônes items :              x=176, y=112, w=160, h=48
```

### Equipment.png (160x384)
```
Mannequin + panneau (1) :   x=0,   y=0,   w=160, h=128
Mannequin + panneau (2) :   x=0,   y=128, w=160, h=128
Mannequin petit :           x=0,   y=256, w=80,  h=96
Grille EQUIPMENT :          x=80,  y=256, w=80,  h=96
Mannequin seul + icônes :   x=0,   y=352, w=160, h=32
```

### Buttons.png (400x528)
```
Petits boutons carrés :     Ligne 0, environ 24x24 chacun
Boutons rectangulaires :    ~96x16 chacun, 4 états par ligne
INVENTORY (4 états) :       y≈416, x=0/96/192/288, w=96, h=16
EQUIPMENT (4 états) :       y≈432, x=0/96/192/288, w=96, h=16
```

### Icons.png (96x304)
```
Grille de 6 colonnes × 19 lignes, icônes de 16×16
Chaque icône : x = colonne*16, y = ligne*16
```

---

## Conseils supplémentaires

1. **Teste souvent** : Après chaque changement, lance le jeu (F5) pour vérifier le rendu en jeu (pas seulement dans l'éditeur)

2. **Cohérence visuelle** : Utilise le même type de panneau (Inventory.png petit panneau) pour TOUS tes panneaux (inventaire, personnage, journal, dialogue) pour un look unifié

3. **Scale x2 ou x3** : Si les textures apparaissent trop petites, souviens-toi que tes sprites sont en pixel art. Tu peux soit :
   - Agrandir les textures avec le Scale du noeud
   - Augmenter les dimensions des panels/containers

4. **Marges internes** : Après avoir changé le fond d'un panneau, les labels et containers à l'intérieur risquent d'être décalés. Ajuste les `offset_left/top/right/bottom` ou les marges du conteneur pour que le contenu soit bien dans la zone "intérieure" du panneau

5. **Font pixel art** : Pour un rendu vraiment cohérent, cherche une police pixel art gratuite (par ex. "Press Start 2P", "Silkscreen", "Pixel Operator") et applique-la comme Theme global dans Project Settings > GUI > Theme

6. **Fichiers .import** : Si une texture apparaît floue, vérifie son fichier `.import` et assure-toi que `filter` est bien désactivé. Tu peux aussi configurer ça globalement dans Project Settings > Rendering > Textures > Canvas Textures > Default Texture Filter → `Nearest`
