# SASS Build System - Quick Start

## Installation

```bash
cd portal-app
npm install
```

## Entwicklung

**Option 1: Watch-Mode (empfohlen für Entwicklung)**
```bash
npm run watch
```
Ändert `main.scss` automatisch → `main.css` wird generiert

**Option 2: Einmalige Kompilierung**
```bash
npm run compile
```

**Option 3: Bash-Script**
```bash
chmod +x watch-sass.sh
./watch-sass.sh
```

## Production Build

```bash
npm run build
```
Erstellt komprimierte CSS-Datei ohne Source Maps.

## Template-Anpassung

### Vorher (alte CSS-Dateien):
```html
<link href="$resources/css/theme.css" rel="stylesheet"/>
<link href="$resources/css/document.css" rel="stylesheet"/>
<link href="$resources/css/sticky-footer-navbar.css" rel="stylesheet"/>
```

### Nachher (SASS-generierte Datei):
```html
<link href="$resources/css/main.css" rel="stylesheet"/>
```

## Betroffene Templates

- `templates/page.html`
- `templates/pageWorks.html`
- `templates/landingPage.html`

## Farben anpassen

Alle Farben in [`resources/sass/_variables.scss`](resources/sass/_variables.scss):

```scss
$baudi-green: rgba(0, 174, 0, 0.9);  // Primärfarbe
$gray-dark: #212529;                  // Navigation
```

## Troubleshooting

**Problem**: `sass: command not found`
```bash
npm install -g sass
# oder
npm install
```

**Problem**: Änderungen werden nicht übernommen
1. SASS neu kompilieren: `npm run compile`
2. Browser-Cache leeren (Cmd+Shift+R)

**Problem**: Fehler beim Kompilieren
- Syntax in `.scss`-Dateien prüfen
- Variablen-Namen korrekt?
- Alle Dateien in `main.scss` importiert?
