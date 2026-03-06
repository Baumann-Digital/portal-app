# SASS Structure for Baumann-Digital

Diese SASS-Struktur ersetzt die bisherigen CSS-Dateien und ermöglicht flexibles, wartbares Styling.

## Struktur

```
resources/sass/
├── main.scss              # Haupt-SCSS-Datei (importiert alle anderen)
├── _variables.scss        # Farben, Schriftarten, Abstände
├── _mixins.scss          # Wiederverwendbare Mixins
├── _navigation.scss      # Navigation & Menü
├── _buttons.scss         # Button-Styles
├── _tables.scss          # Tabellen für Works, Sources, etc.
├── _registry.scss        # Register-Komponenten
├── _components.scss      # Allgemeine Komponenten
├── _document.scss        # Dokument-spezifische Styles
├── _sticky-footer.scss   # Footer-Layout
└── _links.scss           # Link-Styles
```

## Kompilierung

### Mit Node-SASS (empfohlen)

```bash
# Installation
npm install

# Development (mit Watch-Mode)
npm run watch

# Production Build (compressed)
npm run build

# Einmalige Kompilierung
npm run compile
```

### Mit Dart Sass (alternativ)

```bash
# Installation
npm install -g sass

# Kompilierung
sass resources/sass/main.scss resources/css/main.css

# Watch-Mode
sass --watch resources/sass/main.scss:resources/css/main.css
```

### Mit Ruby Sass (veraltet, aber weiterhin funktional)

```bash
sass resources/sass/main.scss resources/css/main.css
```

## Variablen anpassen

Alle Farben und Abstände sind in [`_variables.scss`](sass/_variables.scss) definiert:

```scss
// Primärfarben
$baudi-green: rgba(0, 174, 0, 0.9);
$baudi-dark-green: #2B8E00;

// Graustufen
$gray-dark: #212529;
$gray: #6c757d;
$gray-light: #f8f9fa;
```

## Mixins verwenden

Wiederverwendbare Patterns in [`_mixins.scss`](sass/_mixins.scss):

```scss
// Border Radius
@include border-radius(4px);

// Transition
@include transition(all 0.3s ease);

// Responsive Breakpoints
@include respond-to('lg') {
  // Styles für große Bildschirme
}

// Button Variant
@include button-variant($background, $border);
```

## Neue Komponenten hinzufügen

1. Neue Datei erstellen: `_komponente.scss`
2. In `main.scss` importieren:
   ```scss
   @import "komponente";
   ```
3. SASS kompilieren

## Migration von CSS zu SASS

Die bisherigen CSS-Dateien wurden in folgende SASS-Dateien konvertiert:

- `theme.css` → `_components.scss`, `_tables.scss`, `_registry.scss`
- `document.css` → `_document.scss`
- `sticky-footer-navbar.css` → `_sticky-footer.scss`
- Inline-Styles in Templates → `_navigation.scss`, `_buttons.scss`, `_links.scss`

## Output

Nach der Kompilierung entsteht:
- `resources/css/main.css` - Unkomprimierte Version
- `resources/css/main.css.map` - Source Map für Debugging

## VS Code Integration

Empfohlene Extension: [Live Sass Compiler](https://marketplace.visualstudio.com/items?itemName=ritwickdey.live-sass)

Settings in `.vscode/settings.json`:
```json
{
  "liveSassCompile.settings.formats": [
    {
      "format": "expanded",
      "extensionName": ".css",
      "savePath": "/resources/css"
    }
  ],
  "liveSassCompile.settings.generateMap": true
}
```

## Vorteile gegenüber CSS

✅ **Variablen**: Zentrale Farbdefinition  
✅ **Nesting**: Übersichtlichere Struktur  
✅ **Mixins**: Wiederverwendbare Code-Blöcke  
✅ **Partials**: Modulare Dateistruktur  
✅ **Imports**: Zusammenführung mehrerer Dateien  
✅ **Funktionen**: Berechnungen (darken, lighten, etc.)

## Template-Anpassung

In den Templates muss die CSS-Referenz angepasst werden:

```html
<!-- Vorher -->
<link href="$resources/css/theme.css" rel="stylesheet"/>
<link href="$resources/css/document.css" rel="stylesheet"/>
<link href="$resources/css/sticky-footer-navbar.css" rel="stylesheet"/>

<!-- Nachher -->
<link href="$resources/css/main.css" rel="stylesheet"/>
```
