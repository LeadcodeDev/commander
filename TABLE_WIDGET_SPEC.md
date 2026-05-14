# Table Widget — Specification

> **Status**: Draft v0.1
> **Target**: `package:commander_ui/tui.dart` — remplace l'actuel `TableWidget`.

---

## 1. Overview

### Vision
Un widget `Table<T>` typé sur la donnée d'une ligne, qui rend des données tabulaires riches avec colonnes configurables, sélection multi-niveau (cellule / ligne / colonne, coexistantes), tri/filtre via fonctions, scroll bidirectionnel, et rendu de cellule customisable.

### Problem statement
Le `TableWidget` actuel ne sait afficher que des `List<List<String>>` avec largeurs uniformes et sélection de ligne basique. Pour des cas réels (dashboard k9s-like, table de logs, navigateur de DB) il manque :
- Définition typée des colonnes (`TableColumn<T>` avec builder par cellule).
- Système de largeur similaire au Layout (`length`/`percentage`/`fill`).
- Tri et filtre via callbacks pures.
- Scroll horizontal.
- Sélection à granularité cellule, ligne, ou colonne.
- Headers stylables et désactivables.

### Proposed solution
Un nouveau `Table<T>` qui :
- Prend `items: List<T>` (1 item = 1 ligne) et `columns: List<TableColumn<T>>`.
- Largeur de colonne définie par un `TableConstraint` (length, percentage, fill). Par défaut : distribue 100 % uniformément si aucune contrainte.
- Curseur (rowIndex, colIndex) navigable ↑↓←→.
- Sélection : 3 ensembles indépendants (cells, rows, columns) activables individuellement via flags.
- Tri via `sortBy: int Function(T, T)?` (callback pur), filtre via `filter: bool Function(T)?` (callback pur). Appliqués à chaque frame.
- Headers customisables (style, désactivable).

Remplace l'ancien `TableWidget` (renommé en `LegacyTable` pour ne pas casser brutalement, ou supprimé si non utilisé — à trancher).

### Target users
Tout utilisateur de `commander_ui/tui.dart` construisant des UIs tabulaires.

---

## 2. Goals & Non-Goals

### Goals
- **G1.** Colonnes typées : `TableColumn<T>(title, width, cellBuilder)`.
- **G2.** Largeurs via `TableConstraint` (length/percentage/fill), default = 100 % réparti uniformément.
- **G3.** Sélection multi-niveau (cell + row + column) avec sets indépendants.
- **G4.** Tri et filtre via fonctions pures appliquées en interne.
- **G5.** Scroll vertical + horizontal automatique.
- **G6.** Headers stylables, désactivables.
- **G7.** Custom rendering par cellule via builder retournant un `Widget`.
- **G8.** Compatibilité focus / hit-test du framework.

### Non-Goals
- **NG1.** Pas d'édition inline des cellules (read-only v1).
- **NG2.** Pas de freeze de colonne (column pinning).
- **NG3.** Pas de groupement / sections de lignes.
- **NG4.** Pas de redimensionnement interactif des colonnes (drag).
- **NG5.** Pas de tri multi-colonne natif (l'utilisateur peut composer dans son `sortBy`).
- **NG6.** Pas d'UI de filtre intégrée (pas de champ input) — le filtre est piloté par prop.
- **NG7.** Pas de virtualization async (les items sont tous chargés en mémoire).

---

## 3. User Stories

- **US1.** Afficher une liste d'utilisateurs avec colonnes `Name`, `Email`, `Status` chacune avec sa largeur et son style de cellule.
- **US2.** Naviguer la table avec les flèches : `↑/↓` change la ligne active, `←/→` change la colonne active (avec scroll horizontal si nécessaire).
- **US3.** Sélectionner plusieurs lignes (mode rows) avec `Espace`, puis valider la sélection.
- **US4.** Sélectionner une cellule unique (mode cells) avec `Espace`, par exemple pour la copier.
- **US5.** Activer simultanément la sélection ligne ET cellule : `Espace` = cell, `Shift+Espace` = row.
- **US6.** Trier la table en passant un comparateur via prop `sortBy: int Function(User, User)`.
- **US7.** Filtrer la table en passant `filter: bool Function(User)` (par exemple `user.active`).
- **US8.** Désactiver les headers (`showHeader: false`) pour un tableau pur de données.
- **US9.** Table plus large que le parent : `←/→` scrollent horizontalement.

### Edge cases
- Liste vide → afficher un placeholder centré.
- 0 colonnes → erreur d'assertion.
- Toutes colonnes en `length` mais somme < parent → reste vide à droite (pas d'étalement automatique).
- Toutes colonnes en `fill` → réparties à parts égales.
- Filtre supprimant tout → placeholder "No match".
- Cursor sur une ligne qui disparaît (re-tri / re-filtre) → clamp au plus proche.

---

## 4. Functional Requirements

### 4.1 API publique (M)

```dart
class TableColumn<T> {
  final String title;
  final TableConstraint width;
  final TableCellBuilder<T> cellBuilder;
  final Style? headerStyle;        // override du theme.text.title
  final TextAlign headerAlign;
  final TableSortKey<T>? sortKey;  // optionnel : extraire la clé de tri par colonne

  const TableColumn({
    required this.title,
    required this.cellBuilder,
    this.width = const TableConstraint.fill(1),
    this.headerStyle,
    this.headerAlign = TextAlign.left,
    this.sortKey,
  });
}

sealed class TableConstraint {
  const TableConstraint();
  const factory TableConstraint.length(int value) = _Length;
  const factory TableConstraint.percentage(int value) = _Percentage;
  const factory TableConstraint.fill(int weight) = _Fill;
}

class TableCellState {
  final bool isActive;       // curseur sur cette cellule
  final bool isRowActive;    // curseur sur la ligne (peu importe colonne)
  final bool isColumnActive; // curseur sur la colonne
  final bool isCellSelected;
  final bool isRowSelected;
  final bool isColumnSelected;
  final bool isFocused;
  final int rowIndex;        // index dans items SOURCE
  final int columnIndex;
}

typedef TableCellBuilder<T> = Widget Function(T item, TableCellState state);
typedef TableSortKey<T> = Object Function(T item);

class TableState<T> {
  int activeRow = 0;
  int activeColumn = 0;
  int verticalScroll = 0;
  int horizontalScroll = 0;
  final Set<({int row, int col})> selectedCells = {};
  final Set<int> selectedRows = {};
  final Set<int> selectedColumns = {};
  bool initialized = false;
}

class Table<T> implements FocusableWidget {
  final Key id;
  final List<T> items;
  final List<TableColumn<T>> columns;
  final TableState<T> state;

  // Headers
  final bool showHeader;
  final Style? headerStyle;
  final Style? headerSeparatorStyle;
  final String headerSeparator;   // default '─'

  // Selection (coexistantes)
  final bool selectCells;
  final bool selectRows;
  final bool selectColumns;

  // Sort & filter (pure functions)
  final int Function(T a, T b)? sortBy;
  final bool Function(T item)? filter;

  // Callbacks
  final void Function(int rowIndex, T item)? onRowActivated;
  final void Function(Set<int> rows)? onRowsSelectionChanged;
  final void Function(Set<int> columns)? onColumnsSelectionChanged;
  final void Function(Set<({int row, int col})> cells)? onCellsSelectionChanged;

  const Table({
    required this.id,
    required this.items,
    required this.columns,
    required this.state,
    this.showHeader = true,
    this.headerStyle,
    this.headerSeparatorStyle,
    this.headerSeparator = '─',
    this.selectCells = false,
    this.selectRows = false,
    this.selectColumns = false,
    this.sortBy,
    this.filter,
    this.onRowActivated,
    this.onRowsSelectionChanged,
    this.onColumnsSelectionChanged,
    this.onCellsSelectionChanged,
  }) : assert(columns.length > 0);
}
```

### 4.2 Colonnes et largeurs (M)

**Description.** Chaque `TableColumn<T>` a une `TableConstraint` qui détermine sa largeur dans l'aire allouée :
- `TableConstraint.length(n)` : largeur fixe en cells.
- `TableConstraint.percentage(p)` : pourcentage de la largeur totale.
- `TableConstraint.fill(weight)` : pondération du remplissage de l'espace restant.

**Algorithme de répartition** (similaire à `Layout.split`) :
1. Soustraire la largeur totale des `length`.
2. Soustraire les `percentage` (% du total initial).
3. Le reste est réparti entre les `fill` proportionnellement à leur weight.
4. **Default** : si une colonne n'a pas de contrainte explicite (constructor sans `width`), elle reçoit `TableConstraint.fill(1)` → si AUCUNE colonne n'a de width, toutes sont `fill(1)` → réparties à parts égales (chacune = 100 % / N).

**Séparateur entre colonnes** : 1 cell de padding par défaut (espace). Pas de séparateur visuel (pas de `│` entre colonnes — peut être ajouté en option `columnSeparator: String?`).

**Largeur insuffisante** : si la somme des `length` dépasse la largeur disponible, scroll horizontal activé (cf. §4.6). Aucune colonne n'est masquée.

**Acceptance criteria :**
- 3 colonnes sans `width` → chacune fait `parent.width / 3` (au pixel près, dernier prend le reste).
- 1 colonne `length(10)` + 2 `fill(1)` → 10 fixe + reste réparti 50/50.
- 1 `length(10)` + 1 `percentage(30)` + 1 `fill(1)` → 10 + 30 % + reste.

### 4.3 Headers (S)

**Description.** Première ligne du widget. Affiche les titres des colonnes.

**Comportement :**
- `showHeader: true` (default) → ligne header + ligne séparateur en dessous (`headerSeparator` répété).
- `showHeader: false` → pas de header ni séparateur, gain de 2 lignes pour les données.
- Style par défaut : `theme.text.title` (gras).
- Override globalement via `headerStyle` ou par colonne via `column.headerStyle`.
- Séparateur (1 ligne) stylable via `headerSeparatorStyle`.
- Alignement par colonne via `column.headerAlign`.

**Acceptance criteria :**
- Avec `showHeader: true` et parent.height = 10 → 1 ligne header + 1 ligne séparateur + 8 lignes data.
- Avec `showHeader: false` → 10 lignes data, scrollables.
- Titles tronqués si plus longs que la largeur de colonne (avec `…` final).

### 4.4 Navigation & curseur (M)

**Description.** Un curseur 2D `(activeRow, activeColumn)` :
- `↑/↓/j/k` → bouge `activeRow` ± 1 (clamp à `[0, filteredItems.length - 1]`).
- `←/→/h/l` → bouge `activeColumn` ± 1 (clamp à `[0, columns.length - 1]`).
- `PageUp/PageDown` → saut de `visibleRows`.
- `Home/End` → première/dernière ligne (`activeRow`).
- `Ctrl+Home/Ctrl+End` → première/dernière cellule de la ligne (`activeColumn = 0` ou `last`).

**Scroll suit le curseur** (cf. §4.6).

**Acceptance criteria :**
- Curseur initial : `(0, 0)`.
- ↓ depuis dernière ligne → no-op (clamp).
- → depuis dernière colonne → no-op (clamp).
- Si le curseur sort du viewport vertical → `verticalScroll` ajusté.
- Si le curseur sort du viewport horizontal → `horizontalScroll` ajusté.

### 4.5 Sélection (M)

**3 ensembles indépendants** activables individuellement :

```dart
Table(
  selectCells: true,    // active la sélection de cellules individuelles
  selectRows: true,     // active la sélection de lignes
  selectColumns: true,  // active la sélection de colonnes
  ...
)
```

**Raccourcis clavier :**
| Mode actif | Espace | Shift+Espace | Alt+Espace |
|---|---|---|---|
| `selectCells` seul | toggle cell | — | — |
| `selectRows` seul | toggle row | — | — |
| `selectColumns` seul | toggle column | — | — |
| `selectCells + selectRows` | toggle cell | toggle row | — |
| `selectCells + selectColumns` | toggle cell | — | toggle column |
| `selectRows + selectColumns` | toggle row | — | toggle column |
| Tous les 3 | toggle cell | toggle row | toggle column |

**Règle de fallback :** si aucun mode n'est activé, `Espace` est ignoré (return false → bubble).

**Sets stockés dans `state` :**
- `state.selectedCells: Set<({int row, int col})>`
- `state.selectedRows: Set<int>`
- `state.selectedColumns: Set<int>`

**Callbacks :**
- `onCellsSelectionChanged(Set<({int, int})>)` à chaque toggle de cell.
- `onRowsSelectionChanged(Set<int>)` à chaque toggle de row.
- `onColumnsSelectionChanged(Set<int>)` à chaque toggle de column.

**Entrée** déclenche `onRowActivated(rowIndex, item)` (toujours, indépendant des modes de sélection).

**Visuel :**
- Cellule active (curseur) : `bg = primary` + `fg = background`.
- Cellule sélectionnée : bg = `primary.dim` (ou un autre style, à customiser via prop `selectedStyle`).
- Ligne sélectionnée : toute la ligne avec `bg = primary.dim`.
- Colonne sélectionnée : toute la colonne avec `bg = primary.dim`.
- Cumul : si une cellule est dans une ligne ET colonne sélectionnée → merge.

**Acceptance criteria :**
- Avec `selectCells: true`, Espace → `state.selectedCells.contains((row: 0, col: 0))`.
- Avec `selectRows: true` + `selectCells: true`, Shift+Espace ne modifie que `selectedRows`.
- `Espace` quand aucune sélection activée → no-op, l'event bubble (return false depuis `onKey`).

### 4.6 Scroll bidirectionnel (M)

**Vertical (`state.verticalScroll`) :**
- Suit `activeRow` : si `activeRow < verticalScroll` → `verticalScroll = activeRow`. Si `activeRow >= verticalScroll + visibleRows` → `verticalScroll = activeRow - visibleRows + 1`.
- `visibleRows = parent.height - headerLines` (où `headerLines = 2` si showHeader, `0` sinon).

**Horizontal (`state.horizontalScroll`) :**
- Suit `activeColumn` : analogue au vertical mais sur les colonnes.
- `visibleColumns` calculé dynamiquement selon la largeur cumulée des colonnes à partir de `horizontalScroll`.
- Quand le curseur dépasse la zone visible → scroll d'1 colonne à la fois.

**Indicateurs visuels (S) :**
- `←` ou `→` discret dans le coin droit du header si scroll horizontal possible.
- Pas de scrollbar verticale visuelle (cohérent avec Select).

**Acceptance criteria :**
- Table 10×10 dans un parent 80×6 (avec header) → 4 lignes data visibles, scroll vertical fonctionne.
- 6 colonnes total = 100 cells, parent.width = 50 → scroll horizontal nécessaire, `→` scrolle.

### 4.7 Tri (M)

**Description.** `sortBy: int Function(T a, T b)?` est appliqué à chaque frame sur `items` (après filtre).

**Comportement :**
- Pure function (pas d'effet de bord).
- Re-tri à chaque frame si la fonction change OU si `items` change (référence).
- L'utilisateur peut changer `sortBy` dynamiquement (par exemple en réponse à un header clic ou shortcut clavier qu'il gère lui-même).

**Note :** la table n'expose PAS d'UI de tri (pas de cliquer sur header pour trier). L'utilisateur pilote via la prop.

**Acceptance criteria :**
- Avec `sortBy: (a, b) => a.name.compareTo(b.name)` → items affichés triés par nom.
- Changer `sortBy` au render suivant → table re-trie immédiatement.
- `state.activeRow` reste sur le même item après tri (la table cherche l'ancien item dans la nouvelle liste et remet le curseur dessus).

### 4.8 Filtre (M)

**Description.** `filter: bool Function(T item)?` est appliqué à chaque frame **avant** le tri.

**Comportement :**
- Pure function.
- Items dont `filter` retourne `false` sont exclus du rendu.
- Les indices `state.activeRow`, `selectedRows`, etc. réfèrent à la liste **filtrée+triée** (pas à `items` source).

**Edge case :** si après filtre il ne reste rien → afficher placeholder centré "No match" (ou `placeholder` prop si on en ajoute une).

**Acceptance criteria :**
- `filter: (item) => item.active` → seuls les actifs visibles.
- Filtre + tri : `filter` appliqué d'abord, puis `sortBy` sur le résultat.

### 4.9 Custom rendering par cellule (M)

**`cellBuilder`** appelé pour chaque cellule visible :

```dart
TableColumn<User>(
  title: 'Status',
  width: TableConstraint.length(10),
  cellBuilder: (user, state) => Text(
    user.status,
    style: state.isRowSelected
        ? Style(bold: true, fg: Color.yellow)
        : (user.status == 'ok' ? Style(fg: Color.green) : Style(fg: Color.red)),
  ),
);
```

**Garanties :**
- Appelé uniquement pour les cellules visibles dans le viewport (perf).
- L'aire allouée à chaque cellule fait 1 cell de haut × largeur de colonne.
- `state.rowIndex` et `state.columnIndex` sont les indices dans la liste **filtrée+triée**.

### 4.10 Placeholder (S)

- `placeholder: String` prop. Default : `'No items'`.
- Affiché centré si `items.isEmpty` ou si filtre vide.

### 4.11 Auto-row activation (S)

- `Entrée` sur la ligne active → `onRowActivated(activeRow, item)`.
- Comportement complémentaire à la sélection : permet d'activer une ligne sans la sélectionner.

---

## 5. Non-Functional Requirements

### Performance
- **NF1.** Render < 5ms pour 1000 lignes × 10 colonnes (seuls les items dans le viewport rendus).
- **NF2.** Filter+sort recompute < 10ms pour 10 000 lignes.
- **NF3.** Pas d'allocation `Set`/`Map` en hot path.

### Maintainability
- **NF4.** Coverage > 80 % sur algos (width split, scroll, sélection).
- **NF5.** Dartdoc public à 100 %.

---

## 6. Technical Architecture

### Fichiers à modifier
```
lib/src/tui/widgets/list/
└── table.dart          # ← remplace l'actuel TableWidget
```

L'ancien `TableWidget` est :
- **Option A** : remplacé entièrement par le nouveau `Table<T>` (breaking).
- **Option B** : renommé en `LegacyTable` pour migration douce.
- **Recommandation** : Option A (le widget actuel est très basique, peu d'usage probable).

### Algorithme de répartition des largeurs

```dart
List<int> computeColumnWidths(List<TableColumn<T>> cols, int totalWidth, int gap) {
  final n = cols.length;
  final widths = List<int>.filled(n, 0);
  var remaining = totalWidth - gap * (n - 1).clamp(0, n);

  // Pass 1: length
  for (var i = 0; i < n; i++) {
    final c = cols[i].width;
    if (c is _Length) {
      widths[i] = c.value.clamp(0, remaining);
      remaining -= widths[i];
    }
  }

  // Pass 2: percentage (% du total initial)
  for (var i = 0; i < n; i++) {
    final c = cols[i].width;
    if (c is _Percentage) {
      final w = (totalWidth * c.value / 100).round().clamp(0, remaining);
      widths[i] = w;
      remaining -= w;
    }
  }

  // Pass 3: fill (proportionnel au weight)
  var totalWeight = 0;
  final fillIndices = <int>[];
  for (var i = 0; i < n; i++) {
    final c = cols[i].width;
    if (c is _Fill) {
      totalWeight += c.weight;
      fillIndices.add(i);
    }
  }
  if (fillIndices.isNotEmpty && remaining > 0) {
    var allocated = 0;
    for (var k = 0; k < fillIndices.length; k++) {
      final i = fillIndices[k];
      final c = cols[i].width as _Fill;
      final w = k == fillIndices.length - 1
          ? remaining - allocated
          : (remaining * c.weight / totalWeight).round();
      widths[i] = w;
      allocated += w;
    }
  }

  return widths;
}
```

### Sort + filter pipeline

```dart
List<T> _derivedItems() {
  var work = items;
  if (filter != null) work = work.where(filter!).toList();
  if (sortBy != null) work = [...work]..sort(sortBy!);
  return work;
}
```

### Selection key dispatch

Dans `onKey`, ordre de priorité :
1. Navigation (arrows, PageUp/Down, Home/End).
2. Enter → `onRowActivated`.
3. Selection via Espace + modifiers :
   - Espace seul → cell si `selectCells`, sinon row si `selectRows`, sinon column si `selectColumns`.
   - Shift+Espace → row si `selectRows && selectCells`.
   - Alt+Espace → column si `selectColumns` (et si Shift+Espace non utilisé).
4. Sinon → return false (bubble).

---

## 7. Constraints & Assumptions

- C1. Dart 3.3+.
- C2. T doit avoir `==`/`hashCode` corrects (utilisé pour préserver `activeRow` après tri).
- C3. Le widget remplace `TableWidget`. Note CHANGELOG.

---

## 8. Risks & Mitigations

| ID | Risk | Mitigation |
|---|---|---|
| R1 | Performance sur très grands datasets (sort+filter à chaque frame) | Cache le résultat tant que `items.identical`, `sortBy.identical`, `filter.identical` ne changent pas. |
| R2 | UX des sélections coexistantes confuse | Doc claire + exemples + un Paragraph d'aide affiché par défaut sous la table. |
| R3 | Curseur perdu après changement de filtre/tri | Sauvegarder l'item référence et le relocaliser. |
| R4 | Scroll horizontal cassant le rendering des bordures de cellule | Pas de bordures par défaut (juste espacement), à ajouter prudemment. |

---

## 9. Success Metrics

- M1. Nouvel exemple `15_table.dart` démontre cell+row+column selection, sort, filter, custom cell rendering.
- M2. Tests unitaires couvrent : largeur split, navigation, scroll, sélection multi-mode, sort, filter.
- M3. Performance benchmark : 1000 items × 10 columns rendu < 5ms.

---

## 10. Open Questions

- **OQ1.** L'ancien `TableWidget` est-il référencé quelque part ? Si non, on le remplace. Si oui, on rename en `LegacyTable`.
- **OQ2.** Faut-il un séparateur visuel `│` entre colonnes (prop `columnSeparator: String?`) ? Propose : pas v1, espacement uniquement.
- **OQ3.** Tri multi-colonne via `sortBy` composé (l'user le fait) ou un mécanisme dédié ? Propose : user compose lui-même.
- **OQ4.** Indicateurs `←/→` visuels pour le scroll horizontal possible ? Propose : oui v1, dans le coin droit du header.
- **OQ5.** Différencier style "cellule sélectionnée" vs "cellule active+sélectionnée" ? Propose : oui, deux styles distincts dans le thème ou via prop.
- **OQ6.** Que faire si l'utilisateur change `items` sans changer de référence (mutation in-place) ? Propose : non supporté, doc explicite.

---

*Fin de spec.*
