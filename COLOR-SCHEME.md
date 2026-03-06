# BauDi Farbschema - Erweiterte Palette

Das Portal verwendet jetzt ein erweitertes Farbschema mit drei Hauptfarben:

## 🎨 Farbpalette

### Primärfarbe - Grün
- **Hauptfarbe**: `#00AE00`
- **Verwendung**: Buttons, Links, Hauptnavigation, primäre Aktionen
- **Hell**: `rgba(0, 174, 0, 0.1)` für subtile Hintergründe
- **Dunkel**: `#2B8E00` für Akzente

### Akzentfarbe - Lila
- **Hauptfarbe**: `#AE0062`
- **Verwendung**: Hover-Effekte, interaktive Elemente, sekundäre Aktionen
- **Hell**: `rgba(174, 0, 98, 0.1)` für Hover-Hintergründe
- **Gedämpft**: `rgba(174, 0, 98, 0.8)` für dezente Akzente

### Flächenfarbe - Orange
- **Hauptfarbe**: `#D96200`
- **Verwendung**: Größere Hintergrundflächen (z.B. XML-Vorschau), Panels
- **Hell**: `rgba(217, 98, 0, 0.08)` für subtile Hintergründe
- **Gedämpft**: `rgba(217, 98, 0, 0.15)` für sichtbarere Flächen

## 📍 Einsatzgebiete

### Grün (#00AE00)
- ✅ Primäre Buttons (`.btn-primary`)
- ✅ Haupt-Links in Content-Bereichen
- ✅ Navigations-Tabs (Standard-Zustand)
- ✅ Checkboxes und Radio-Buttons
- ✅ Primäre Icons und Indikatoren

### Lila (#AE0062)
- 🎯 Button Hover-Zustand
- 🎯 Link Hover-Zustand  
- 🎯 Tab Hover-Zustand
- 🎯 Registry-Einträge Hover
- 🎯 Interaktive Elemente Hover
- 🎯 Badges mit `.badge-accent`
- 🎯 Highlight-Bereiche mit `.highlight-purple`

### Orange (#D96200)
- 🧡 XML-Ansicht Hintergrund (`.xml-view-card`)
- 🧡 Große Informations-Panels (`.panel-orange`)
- 🧡 Dokumentations-Bereiche
- 🧡 Hervorgehobene Content-Sektionen
- 🧡 Status-Indikatoren

## 🎨 Neue CSS-Klassen

### Accent Badge
```html
<span class="badge badge-accent">Neu</span>
```

### Orange Panel
```html
<div class="panel-orange">
  Wichtige Information mit Orange-Hintergrund
</div>
```

### Purple Highlight
```html
<span class="highlight-purple">Hervorgehobener Text</span>
```

### Status-Indikatoren
```html
<span class="status-accent purple"></span>
<span class="status-accent orange"></span>
<span class="status-accent green"></span>
```

## 🔧 CSS Custom Properties

Die Farben sind auch als CSS-Variablen verfügbar:

```css
var(--baudi-green)      /* #00AE00 */
var(--baudi-purple)     /* #AE0062 */
var(--baudi-orange)     /* #D96200 */
var(--primary)          /* alias für --baudi-green */
var(--accent)           /* alias für --baudi-purple */
```

## 📝 Verwendungsrichtlinien

### ✅ DO
- Grün für primäre Aktionen und Links
- Lila für Hover-Zustände und Interaktivität
- Orange für größere Informations-Flächen
- Farben sparsam und gezielt einsetzen

### ❌ DON'T
- Nicht alle drei Farben gleichzeitig in einem Element
- Orange nicht für kleine UI-Elemente (zu dominant)
- Lila nicht als Hintergrundfarbe für große Flächen
- Keine weiteren Farben ohne Abstimmung hinzufügen

## 🚀 Migration

Vorhandene Elemente wurden automatisch angepasst:
- ✅ Alle Tabs zeigen Lila bei Hover
- ✅ Content-Links zeigen Lila bei Hover
- ✅ Buttons zeigen Lila-Hintergrund bei Hover
- ✅ XML-Vorschau hat Orange-Hintergrund
- ✅ CSS Custom Properties erweitert

## 📦 SASS-Variablen

In SASS verwenden:
```scss
$baudi-green          // #00AE00
$baudi-purple         // #AE0062
$baudi-orange         // #D96200
$baudi-light-green    // rgba(0, 174, 0, 0.1)
$baudi-light-purple   // rgba(174, 0, 98, 0.1)
$baudi-light-orange   // rgba(217, 98, 0, 0.08)
```
