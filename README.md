# FieldMark

Eine Garmin Connect IQ App fürs **Kartieren im Gelände**: interessante Objekte
(Pflanzen, Hochsitze, Nisthilfen, Gewässer …) per Tastendruck mit GPS-Koordinate
und Zeitstempel erfassen - ein Druck, ein Punkt, keine Menüs.

Primäres Zielgerät: **Garmin Forerunner 255 Music** (`fr255m`).
Privatprojekt, keine Store-Veröffentlichung geplant.

## Status

Frühe Entwicklung. Die Build-Pipeline steht; die App kompiliert und läuft auf der Uhr.

| Funktion | Stand |
|----------|-------|
| Build & Sideload | ✅ |
| Uhrzeit / Akku-Anzeige | ✅ |
| GPS-Status & -Anzeige | geplant |
| Punkt per Taste speichern (CSV) | geplant |
| Mehrere Kategorien (bis zu 3 Tasten) | geplant |

## Idee in Kürze

- Vor der Aktivität bis zu **3 Kategorien** wählen → eine je Hardwaretaste.
- Ein Tastendruck speichert sofort **GPS-Koordinate + Zeitstempel + Kategorie**.
- Pro Kategorie eine **CSV-Datei**, später per MTP vom Gerät kopierbar.
- GPS-Fix ist **Pflicht** zum Speichern (keine Punkte ohne Position).

## Projektstruktur

```
.devcontainer/   Dev Container (SDK-Toolchain im Container)
source/          Monkey-C-Quellcode (App, Views, Delegates)
resources/       Manifest-Ressourcen (Strings, Drawables)
scripts/         gen-key.sh (Signing-Key), build.sh (Build)
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

## Hinweise

- `keys/` (Signaturschlüssel) und `.devcontainer/devcontainer.env` (Zugangsdaten)
  sind bewusst gitignored und gehören nicht ins Repository.
- Der Entwickler-Schlüssel sollte gesichert werden - ohne ihn lassen sich
  installierte Versionen nicht aktualisieren.

## Lizenz

Noch nicht festgelegt.
