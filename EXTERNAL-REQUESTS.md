# External Requests Modul

## Übersicht

Das `external-requests.xqm` Modul verwaltet alle Anfragen an externe Dienste wie GND, VIAF, Wikidata, Digilib und BLB Karlsruhe.

## Funktionalität

### 1. Caching-System

Alle externen Anfragen werden automatisch gecacht, um:
- Netzwerk-Last zu reduzieren
- Ladezeiten zu verbessern
- Externe APIs zu schonen

**Cache-Konfiguration:**
- Speicherort: `/db/system/cache/external-requests`
- Gültigkeitsdauer: 7 Tage
- Automatische Initialisierung

### 2. Normdaten-Integration

#### GND (Gemeinsame Normdatei)
```xquery
er:fetch-gnd-data($gndId) → RDF/XML Document
er:parse-gnd-data($gndDoc) → Map mit strukturierten Daten
```

Extrahierte Informationen:
- Bevorzugter Name
- Varianten-Namen
- Lebensdaten (Geburt/Tod)
- Geburts-/Sterbeorte
- Berufe
- Biographische Informationen
- Geschlecht
- Wikipedia-Links (via sameAs)

#### VIAF (Virtual International Authority File)
```xquery
er:fetch-viaf-data($viafId) → RDF/XML Document
er:parse-viaf-data($viafDoc) → Map mit VIAF-Daten
```

Extrahierte Informationen:
- VIAF-ID
- Namen-Varianten
- Quellen

#### Wikidata
```xquery
er:fetch-wikidata-by-gnd($gndId) → SPARQL XML Results
er:parse-wikidata($wikidataDoc) → Map mit Wikidata-Daten
```

Extrahierte Informationen von Wikidata:
- Wikidata Item-URI
- Label
- VIAF-ID (wenn vorhanden)
- Bild-URL
- Wikipedia-Artikel (Deutsch/Englisch)

### 3. Kombinierte Normdaten-Abfrage

```xquery
er:get-combined-authority-data($gndId, $viafId) → Combined Map
```

Kombiniert automatisch Daten aus:
- GND
- VIAF
- Wikidata (über GND-ID)

### 4. HTML-Ausgabe

```xquery
er:get-authority-info($gndId, $viafId) → HTML <div>
```

Generiert formatierte HTML-Ausgabe mit Bootstrap-Klassen:
- Responsive 2-Spalten-Layout (Label | Wert)
- Wikipedia-Links (bevorzugt aus Wikidata)
- Wikidata-Bild (falls vorhanden)
- Alle verfügbaren Normdaten

### 5. Digilib-URLs

Helper-Funktionen für Digilib-URL-Konstruktion:

```xquery
er:get-digilib-url($chiffre, $path, $params?) → String
er:get-letter-facsimile-url($letter, $page) → String
er:get-letter-thumbnail-url($id, $page) → String
er:get-source-url($sourceId) → String
```

### 6. Faksimile-Vorschau

```xquery
er:get-facsimile-preview($id, $musicCol, $docCol) → HTML <div>
```

Unterstützt:
- Lokale Digilib-Ressourcen
- BLB Karlsruhe Digitalisate
- Automatische Erkennung basierend auf Source-Chiffre

## Error Handling

Alle Fetch-Funktionen haben eingebautes Error-Handling:

1. **Try-Catch-Blöcke**: Fangen Netzwerkfehler ab
2. **Timeout-Management**: Durch eXist-db's doc() Funktion
3. **Fallback-Werte**: Leere Sequenzen bei Fehlern
4. **Sichere Parsing**: Prüft auf Existenz vor Zugriff

## Template-Integration

### Personen (viewPerson.html)

```html
<div data-template="app:person-gnd-info"/>
```

### Institutionen (viewInstitution.html)

```html
<div data-template="app:institution-gnd-info"/>
```

Beide Template-Funktionen in `app.xql`:
- `app:person-gnd-info($node, $model)`
- `app:institution-gnd-info($node, $model)`

Diese Funktionen:
1. Extrahieren GND und VIAF IDs aus dem Dokument
2. Rufen `er:get-authority-info()` auf
3. Geben formatiertes HTML zurück

## Cache-Management

### Cache initialisieren
```xquery
er:init-cache() → Boolean
```

### Cache-Validierung
```xquery
er:is-cache-valid($cacheDoc) → Boolean
```

### Cache leeren
Manuell via eXist-db Dashboard:
1. Collections Browser öffnen
2. `/db/system/cache/external-requests` navigieren
3. Collection löschen (wird bei Bedarf neu erstellt)

## Konfiguration

### Cache-Einstellungen ändern

In `external-requests.xqm`:

```xquery
declare variable $er:cache-collection := '/db/system/cache/external-requests';
declare variable $er:cache-expiry-days := 7;
```

### Timeout anpassen

eXist-db Config:
- In `conf.xml` die HTTP-Client Timeouts konfigurieren
- Standard: 30 Sekunden für doc() Aufrufe

## Performance

### Erste Anfrage (ohne Cache)
- GND: ~500-1000ms
- VIAF: ~500-1000ms  
- Wikidata SPARQL: ~1000-2000ms
- **Total**: ~2-4 Sekunden

### Nachfolgende Anfragen (mit Cache)
- **Total**: < 50ms (lokaler Zugriff)

### Optimierungen
1. Parallele Anfragen nicht implementiert (könnten zukünftig hinzugefügt werden)
2. Cache reduziert Last auf externe APIs
3. 7-Tage Cache-Dauer balanciert Aktualität vs. Performance

## Abhängigkeiten

### XQuery Module
- `config.xqm` - Konfiguration
- `functx.xqm` - String-Utilities
- `xmldb` - Collection-Management

### Externe APIs
- **GND**: https://d-nb.info/gnd/
- **VIAF**: https://viaf.org/
- **Wikidata**: https://query.wikidata.org/sparql

### Namespaces
- `rdf` - http://www.w3.org/1999/02/22-rdf-syntax-ns#
- `gndo` - https://d-nb.info/standards/elementset/gnd#
- `sr` - http://www.w3.org/2005/sparql-results#
- `schema` - http://schema.org/

## Erweiterungsmöglichkeiten

### 1. Wikipedia-Artikel-Text abrufen
```xquery
declare function er:fetch-wikipedia-article($title, $lang) { ... }
```

### 2. Beacon-Integration
Für zusätzliche biographische Quellen

### 3. DBpedia
Weitere Linked-Data Quellen

### 4. Parallele Anfragen
Mit eXist-db async features

### 5. Cache-Statistiken
Monitoring für Cache-Hit-Rate

## Troubleshooting

### Problem: Keine Daten angezeigt

**Lösung:**
1. Prüfen ob GND/VIAF ID im XML vorhanden
2. Cache leeren
3. Externe API-Verfügbarkeit prüfen
4. eXist-db Logs prüfen (`/db/logs/`)

### Problem: Langsame Ladezeiten

**Lösung:**
1. Cache-Gültigkeit prüfen
2. Netzwerkverbindung testen
3. Cache-Collection Berechtigungen prüfen

### Problem: Bilder werden nicht angezeigt

**Lösung:**
1. Wikidata SPARQL-Query testen
2. Bild-URLs auf HTTPS prüfen
3. Content-Security-Policy in eXist-db

## Changelog

### Version 1.0 (März 2026)
- ✅ Initiale Implementation
- ✅ GND-Integration
- ✅ VIAF-Integration
- ✅ Wikidata SPARQL-Integration
- ✅ Caching-System
- ✅ Error-Handling
- ✅ Template-Integration
- ✅ Digilib URL-Helpers
- ✅ BLB Karlsruhe Faksimile-Support

## Autoren

Baumann Digital Portal Team
