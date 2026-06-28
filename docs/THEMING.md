# Theming Documentation — Recipely

This project uses a custom, context-aware theming system for **Colors** and **Typography**, consistent with the app's warm, food-forward visual identity.

---

## 1. Colors

We use a "Foundation Colors" approach defined in `lib/shared/core/theme/app_colors.dart`.

### Available Palettes

| Palette | Description |
|---|---|
| `primary` | Warm orange — the brand's main action color |
| `secondary` | Soft green — freshness and health cues |
| `black` | Neutral dark shades for text and icons |
| `grey` | Neutral grey shades for borders, subtitles |
| `white` | Neutral white/cream shades for backgrounds |
| `error` | Red — form errors, delete actions |
| `success` | Green — saved, cooked, completed states |
| `warning` | Amber — timing alerts, low stock |

### How to Use

Do **NOT** use `Colors.orange` or `Theme.of(context).primaryColor`.  
Access colors directly via `context`:

```dart
// Syntax: context.<palette>.c<shade>
// Shades range from c50 (lightest) to c900 (darkest), c500 is the base.

Container(
  color: context.primary.c500,           // Base Orange
  child: Text(
    "Saved!",
    style: TextStyle(color: context.success.c600),
  ),
)

Scaffold(
  backgroundColor: context.white.c50,   // Warm Cream Background
)

// Disabled state
ElevatedButton(
  style: ButtonStyle(
    backgroundColor: WidgetStateProperty.all(context.grey.c300),
  ),
)
```

### Modifying Colors

Edit hex values in `lib/shared/core/theme/app_colors.dart` inside the `ColorPalette` definitions.

---

## 2. Typography

We use the **Inter** font family via `google_fonts`, with a custom scale defined in `lib/shared/core/theme/app_typography.dart`.

### Available Sizes

| Name | Size | Line Height | Common Use |
|---|---|---|---|
| `display2xl` | 72 | 90 | Hero splash text |
| `displayXl` | 60 | 72 | Onboarding headings |
| `displayLg` | 48 | 60 | Section heroes |
| `displayMd` | 36 | 44 | Screen titles |
| `displaySm` | 30 | 38 | Card headings |
| `displayXs` | 24 | 32 | Sub-headings |
| `textXl` | 20 | 30 | Recipe titles |
| `textLg` | 18 | 28 | Section labels |
| `textMd` | 16 | 24 | Body text |
| `textSm` | 14 | 20 | Metadata, tags |
| `textXs` | 12 | 18 | Captions, timestamps |

Each size has 4 weights: **regular**, **medium**, **semibold**, **bold**.

### How to Use

Do **NOT** use `Theme.of(context).textTheme` or raw `TextStyle(fontSize: 16)`.  
Access typography directly via `context`:

```dart
// Syntax: context.typography.<size>.<weight>

Text(
  recipe.title,
  style: context.typography.textXl.semibold,
);

Text(
  '${recipe.cookTimeMinutes} min · ${recipe.calories} kcal',
  style: context.typography.textSm.regular.copyWith(
    color: context.grey.c600,
  ),
);

Text(
  context.l10n.discoverRecipes,
  style: context.typography.displaySm.bold.copyWith(
    color: context.black.c900,
  ),
);
```

### Modifying Typography

Edit `AppTypographyExtension.main` factory in `lib/shared/core/theme/app_typography.dart`.

---

## 3. Localization

Use the helper context extension to access localized strings.

### How to Use

Do **NOT** use `AppLocalizations.of(context)!.someString`.

```dart
// Syntax: context.l10n.<key>

Text(context.l10n.homeTitle);
Text(context.l10n.startCooking);
```

### Adding New Strings

1. Open `lib/l10n/app_en.arb`.
2. Add your key-value pair.
3. Run `flutter gen-l10n` to regenerate.

---

## 4. Responsive Design

We use `universal_breakpoints` for responsive sizing. Ensure `UniversalBreakpoints().init(context)` is called in `main.dart`.

### Screen Dimensions

- **.sW** — Percent of screen **width** (e.g., `50.sW` = 50% of screen width)
- **.sH** — Percent of screen **height** (e.g., `20.sH` = 20% of screen height)

> ⚠️ `sW` ≠ `sH`. Do not mix them.

```dart
Container(
  width: 90.sW,
  height: 25.sH,
  child: RecipeCard(recipe: recipe),
)
```

### Font Scaling

```dart
Text(
  recipe.title,
  style: TextStyle(fontSize: 16.sF),
)
```

---

## 5. Architecture Laws (Always Enforced)

| ❌ Never | ✅ Always |
|---|---|
| `Colors.orange` | `context.primary.c500` |
| `TextStyle(fontSize: 16)` | `context.typography.textMd.regular` |
| Hardcoded strings in widgets | `context.l10n.someKey` |
| `'assets/images/logo.png'` | `Assets.images.logo.path` |
| `Theme.of(context).textTheme.bodyMedium` | `context.typography.textMd.regular` |
