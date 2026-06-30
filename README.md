# FieldMark

Eine Garmin Connect IQ App fürs **Kartieren im Gelände**: interessante Objekte
(Pflanzen, Hochsitze, Nisthilfen, Gewässer …) per Tastendruck mit GPS-Koordinate
und Zeitstempel erfassen - ein Druck, ein Punkt, keine Menüs.

Primäres Zielgerät: **Garmin Forerunner 255 Music** (`fr255m`).
Privatprojekt, keine Store-Veröffentlichung geplant.

## Status

In Entwicklung. Build, GPS-Anzeige sowie Aufzeichnung und Export funktionieren
auf echter Hardware; die Mehr-Kategorien-Bedienung folgt als Nächstes.

| Funktion | Stand |
|----------|-------|
| Build & Sideload | ✅ |
| Uhrzeit / Akku-Anzeige | ✅ |
| GPS-Status & -Anzeige | ✅ |
| Punkt per Taste speichern (mit GPS-Pflicht + Vibration) | ✅ |
| Export FIT → CSV (`tools/fit2csv.py`) | ✅ |
| Mehrere Kategorien (bis zu 3 Tasten) | in Arbeit |
| Kategorien konfigurierbar | geplant |

## Idee in Kürze

- Vor der Aktivität bis zu **3 Kategorien** wählen → eine je Hardwaretaste.
- Ein Tastendruck speichert sofort **GPS-Koordinate + Zeitstempel + Kategorie**.
- Die Aufzeichnung läuft als Garmin-Aktivität (FIT-Datei); am Rechner wird sie
  pro Kategorie in eine **CSV-Datei** umgewandelt.
- GPS-Fix ist **Pflicht** zum Speichern (keine Punkte ohne Position).

## Projektstruktur

```
.devcontainer/   Dev Container (SDK-Toolchain im Container)
source/          Monkey-C-Quellcode (App, View, Delegate, Controller)
resources/       Manifest-Ressourcen (Strings, Drawables)
scripts/         gen-key.sh (Signing-Key), build.sh (Build)
tools/           fit2csv.py (FIT-Aktivität → CSV pro Kategorie)
manifest.xml     App-Definition (Device, Berechtigungen, API-Level)
monkey.jungle    Build-Konfiguration
```

## Entwicklung

Gebaut wird in einem Dev Container (VS Code + Docker/Podman); das Connect IQ SDK
wird darin automatisch eingerichtet.

### Voraussetzungen

- VS Code mit der Erweiterung *Dev Containers*
- Docker oder Podman
- Ein Garmin-Konto (für den SDK-Download)

### Einrichtung

1. Credentials hinterlegen (wird **nicht** eingecheckt):
   ```bash
   cp .devcontainer/devcontainer.env.example .devcontainer/devcontainer.env
   # GARMIN_USERNAME und GARMIN_PASSWORD eintragen
   ```
   Den `CIQ_AGREEMENT_HASH` prüfen/erneuern mit:
   ```bash
   connect-iq-sdk-manager agreement view
   ```
2. In VS Code: **Dev Containers: Reopen in Container**.
   Beim ersten Start lädt das SDK automatisch (einmalig, einige hundert MB,
   persistiert in einem benannten Volume).

### Build

Im Container-Terminal:

```bash
bash scripts/gen-key.sh    # einmalig: Entwickler-Signaturschlüssel erzeugen
bash scripts/build.sh      # baut bin/fr255m.prg
```

### Auf die Uhr übertragen (Sideload)

Uhr per USB anschließen, dann `bin/fr255m.prg` in den Ordner `GARMIN/Apps/`
auf dem Gerät kopieren und die Uhr sicher auswerfen. Die App erscheint
anschließend in der App-Liste.

## Daten auswerten

Beim Kartieren zeichnet die App eine Garmin-Aktivität auf. Jeder gespeicherte
Punkt wird als Runde (Lap) mit der Kategorie als Datenfeld markiert.

> Hintergrund: Connect IQ erlaubt einer App kein direktes Schreiben beliebiger
> Dateien auf den Massenspeicher - daher der Weg über die FIT-Aktivität.

1. Aktivität beenden (BACK) - die FIT-Datei landet in `GARMIN/Activity/` auf der Uhr.
2. FIT-Datei per USB/MTP auf den Rechner kopieren.
3. In CSV pro Kategorie umwandeln:
   ```bash
   python3 -m venv .venv && source .venv/bin/activate   # einmalig
   pip install fitparse                                  # einmalig
   python3 tools/fit2csv.py ACTIVITY.fit -o export/
   ```
   Ergebnis: je Kategorie eine Datei (z. B. `export/Mahonien.csv`) mit den Spalten
   `timestamp_utc,latitude,longitude,accuracy_m,altitude_m,notes`.

Zum Ansehen auf einer Karte eignet sich die VS-Code-Erweiterung *Geo Data Viewer*
(im Dev Container bereits enthalten): CSV öffnen → "View Map".

## Hinweise

- `keys/` (Signaturschlüssel) und `.devcontainer/devcontainer.env` (Zugangsdaten)
  sind bewusst gitignored und gehören nicht ins Repository.
- Der Entwickler-Schlüssel sollte gesichert werden - ohne ihn lassen sich
  installierte Versionen nicht aktualisieren.
- `export/` und `*.fit` sind gitignored - aufgezeichnete GPS-Tracks gehören
  nicht ins öffentliche Repository.

## Lizenz

Noch nicht festgelegt.
