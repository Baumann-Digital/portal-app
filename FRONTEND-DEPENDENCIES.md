# Frontend-Bibliotheken mit Yarn

Dieses Projekt verwendet **Yarn** für das Management von Frontend-Abhängigkeiten, inspiriert vom [WeGA-WebApp](https://github.com/Edirom/WeGA-WebApp) Projekt.

## Warum Yarn?

Vorteile gegenüber manuell eingecheckten Bibliotheken:
- ✅ **Versionskontrolle**: Alle Abhängigkeiten sind in `package.json` definiert
- ✅ **Kleine Repository-Größe**: `libs/` und `node_modules/` werden nicht ins Git eingecheckt
- ✅ **Einfache Updates**: `yarn upgrade` aktualisiert alle Bibliotheken
- ✅ **Reproduzierbare Builds**: `yarn.lock` gewährleistet identische Versionen

## Installierte Bibliotheken

### Production Dependencies
- **Bootstrap 4.5.3**: CSS Framework
- **jQuery 3.5.0**: JavaScript-Bibliothek
- **Font Awesome 6.0.0**: Icon-Font
- **Waypoints 4.0.1**: Scrolling-Events (für counterup)

### Development Dependencies
- **sass**: SASS/SCSS Compiler
- **minify**: CSS/JS Minification
- **frontend-dependencies**: Automatisches Kopieren in `libs/` Verzeichnis

## Workflow

### 1. Initial Setup
```bash
cd portal-app
yarn install
```

Dies führt automatisch aus:
1. Installation aller Dependencies in `node_modules/`
2. Kopieren benötigter Dateien nach `libs/` via `frontend-dependencies`

### 2. Entwicklung
```bash
# SASS im Watch-Modus
yarn watch

# Einmaliges Kompilieren
yarn compile
```

### 3. Build
```bash
# Vollständiger Build mit Ant
ant dist
```

Der `ant dist` Befehl führt automatisch aus:
1. `yarn install --check-files` - Installiert Dependencies
2. SASS-Kompilierung - Erzeugt `dist/resources/css/main.css`
3. Kopiert `libs/` nach `dist/resources/lib/`
4. Erstellt XAR-Paket

## Verzeichnisstruktur

```
portal-app/
├── package.json              # Yarn-Konfiguration
├── node_modules/             # NPM-Pakete (nicht in Git)
├── libs/                     # Extrahierte Frontend-Libs (nicht in Git)
├── resources/
│   ├── lib/                  # Alte manuelle Bibliotheken (deprecated)
│   ├── sass/                 # SASS-Quelldateien
│   └── css/                  # Kompilierte CSS-Dateien
└── dist/                     # Build-Ausgabe
    └── resources/
        └── lib/              # Kopierte libs für XAR-Paket
```

## Migration von resources/lib/

Die alten manuell eingecheckten Bibliotheken in `resources/lib/` sind jetzt **deprecated** und werden im Build-Prozess **ausgeschlossen**. Sie werden durch die Yarn-verwalteten Versionen in `libs/` ersetzt.

### Änderungen in Templates

Wenn Templates Bibliotheken referenzieren:
- ✅ **Richtig**: `resources/lib/waypoints/lib/jquery.waypoints.min.js`
- ❌ **Alt**: `resources/lib/counterup/jquery.waypoints.min.js`

Nach dem Build werden die Bibliotheken aus `libs/` nach `dist/resources/lib/` kopiert.

## Neue Bibliothek hinzufügen

```bash
# Dependency hinzufügen
yarn add bibliothek-name

# In package.json unter frontendDependencies konfigurieren
{
  "frontendDependencies": {
    "packages": [
      "bibliothek-name/dist/"
    ]
  }
}

# Installieren (extrahiert automatisch nach libs/)
yarn install
```

## CDN vs. lokale Bibliotheken

**Aktuell nutzen wir CDN für:**
- Bootstrap CSS/JS (jsdelivr)
- jQuery (cdnjs)
- Font Awesome (use.fontawesome.com)
- jQuery Easing (cdnjs)

**Lokale Bibliotheken (aus libs/):**
- Waypoints (für counterup-Funktionalität)
- Spezifische BauDi-Assets

**Vorteil CDN**: Schnellere Ladezeiten, Browser-Caching
**Vorteil lokal**: Offline-Verfügbarkeit, keine externen Abhängigkeiten

## Troubleshooting

### yarn: command not found
```bash
# Yarn installieren
npm install -g yarn
# oder via Homebrew (macOS)
brew install yarn
```

### libs/ Verzeichnis ist leer
```bash
# yarn install mit postinstall hook erneut ausführen
yarn install --force
```

### Build schlägt fehl
```bash
# Clean build
ant clean-all
ant dist
```

## Weiterführende Dokumentation

- [Yarn Documentation](https://yarnpkg.com/getting-started)
- [frontend-dependencies](https://github.com/micromata/frontend-dependencies)
- [WeGA-WebApp Build System](https://github.com/Edirom/WeGA-WebApp/blob/develop/build.xml)
