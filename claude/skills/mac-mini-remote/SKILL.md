---
name: mac-mini-remote
description: Claude-Code-Sessions auf dem Mac mini («mini») statt lokal laufen lassen, Projekte dorthin umziehen und Server-Sessions prüfen. Verwenden, sobald es um den mini, Remote-/Server-Sessions, lang laufende Aufgaben, die ohne Laptop weiterlaufen sollen, `claude @mini`, `claude-move`, `.claude-host`, pinke tmux-Tabs, den Anker-tmux (`tmux -L claude`) oder Login-/Schlüsselbund-Probleme auf dem mini geht. Auch nützlich, wenn man auf dem mini selbst läuft.
---

# Claude-Sessions auf dem Mac mini

Ein Mac mini dient als Server für Claude-Code-Sessions (`~/.dots/tmux/claude-hosts`, Name = SSH-Alias `mini`,
pinke Tabs). Projekte, die mit `claude-move` dorthin umgezogen sind, laufen dort dauerhaft weiter (Laptop zu,
unterwegs, Handy über Remote Control) und fühlen sich im lokalen tmux trotzdem wie lokale Sessions an.
Code in `~/.dots` (gleiches Repo auf Laptop und mini, gleiche Pfade und gleicher Benutzername).

## Wo bin ich?

- Existiert `~/Library/LaunchAgents/local.claude-tmux.plist`, läufst du **auf einem Server** (zshrc: `$_claude_server`). `claude` in einem Projekt verbindet sich dort mit der Session des Projekts im Anker (oder startet sie), `claude --here` startet ein separates Claude in der aktuellen Shell.
  Läuft die Shell in `tmux -L claude` (`$TMUX` enthält `/claude,`), bist du eine Server-Session:
  keine Benachrichtigungen, kein Einsortieren (`CLAUDE_TMUX_NOTIFY=0`, `CLAUDE_TMUX_AUTOSORT=0`).
- Sonst bist du auf dem **Laptop**. Ein pinker Tab in tmux bzw. `@claude_host=<server>` auf dem Fenster
  heisst: Dieses Fenster ist per SSH mit einer Session auf dem Server verbunden.

## Befehle (Laptop)

| Befehl | Wirkung |
|---|---|
| `claude` | Lokal, ausser das Projekt liegt auf einem Server → verbindet bzw. startet dort |
| `claude @mini …` / `claude --local …` | Ort explizit wählen |
| `claude-move [<server>]` | Projekt samt Claude-Verlauf auf seinen Standard-Server bzw. den genannten umziehen (mit Prüfung und lokalem Backup). Unterbrochene Kopien setzt ein neuer Aufruf fort. |
| `claude-move local` (`--back`) | Zurückholen (bricht ab, solange die Session auf dem Server läuft) |
| `claude-move --backups` | Lokale Backups unter `~/Library/Application Support/claude-remote/backups/` |
| `mini` (Servername) | In einem Projekt dieses Servers: Shell dort im selben Ordner. Sonst/mit Argumenten: `ssh <server>` |
| `<server>-admin` | SSH als Admin (falls in `~/.ssh/config` eingetragen) |
| `<server>-unlock` | Nach Neustart FileVault per SSH entsperren (Passwort tippt der Benutzer selbst) |

Ein Projekt liegt auf einem Server, wenn seine Wurzel eine `.claude-host` enthält (`host=<server>`)
oder in `~/.config/claude-remote/projects` steht (`<wurzel> <server>`). Eine laufende lokale Session hat immer Vorrang.
Projektwurzel und -name bestimmt `~/.dots/tmux/claude-project.sh`.

## Server-Sessions prüfen (vom Laptop aus)

```bash
ssh mini 'tmux -L claude ls'                                   # laufende Sessions
ssh mini "tmux -L claude list-panes -a -F '#{session_name} #{@claude_state} #{pane_current_path}'"
ssh mini 'tmux -L claude capture-pane -p -t <projekt> | tail -40'   # Bildschirm einer Session lesen
ssh mini 'tmux -L claude run-shell "claude auth status"'      # Login im Anker
```

`@claude_state`: `working`, `waiting` (wartet auf Eingabe), `done`, `idle`. Interaktiv verbinden kann
nur der Benutzer in seinem Terminal (`claude` im Projektordner bzw. `claude @mini`).

## Aufbau, den du kennen musst

- **Anker:** Alle Server-Sessions laufen im tmux-Server `tmux -L claude` mit `~/.dots/tmux/server.conf`
  (unsichtbar: kein Prefix, keine Statusleiste). Er wird vom LaunchAgent `local.claude-tmux`
  **in der grafischen Sitzung** gestartet, damit Sessions Zugriff auf den Schlüsselbund haben (`gh`, Git).
  Das normale `tmux` auf dem Server ist davon getrennt.
- **Ausnahme Login als Datei** (`~/.claude/.credentials.json`, Login per SSH gemacht): Fehlt der Anker,
  startet `claude-remote.sh run` ihn selbst per SSH. Claude ist darin angemeldet, `gh` nur, wenn sein
  Token ebenfalls in einer Datei liegt (`~/.config/gh/hosts.yml`).
- Sonst **nie** per SSH einen `tmux -L claude`-Server starten (z. B. `tmux -L claude new`, wenn keiner läuft):
  Er hätte keinen Schlüsselbund-Zugriff. Prüfen mit `ssh mini 'tmux -L claude run-shell true'`.
  Läuft er nicht, ist niemand grafisch angemeldet → Benutzer per Bildschirmfreigabe anmelden lassen.
- **Claude-Login** auf dem Server: Inhalt von Login-Dateien nie ausgeben oder kopieren, Schlüsselbund-Einträge nicht auslesen.
- **Neue Session:** `~/.dots/tmux/claude-remote.sh run` startet sie inklusive Prüfungen
  (`tmux -L claude new-session -A -s <projekt> -c <ordner> 'claude --remote-control <projekt>'`).
  Beim ersten Start eines Ordners fragt Claude nach Vertrauen; das bestätigt der Benutzer selbst.
- **SSH-Multiplexing:** Die Server-Hosts nutzen `ControlMaster`. `claude-move` kopiert mit eigener Verbindung
  (`ControlPath=none`), sonst blockiert ein grosser rsync jedes andere `ssh` zum Server.

## Verbindung trennen

Lokales Fenster/Pane schliessen (`Ctrl+W`, `exit`, Tab zu) trennt nur die SSH-Verbindung; die Session läuft auf dem Server weiter. `claude` im Ordner verbindet wieder. Nur `/exit` bzw. zweimal Ctrl+C **in Claude** beendet sie.

## Typische Probleme

| Meldung / Symptom | Ursache | Lösung |
|---|---|---|
| «mini not reachable» | Nicht im richtigen Netz, VPN aus | VPN verbinden; ein VPN, das allen Verkehr umleitet, kann andere Netze verdecken (Split-Tunnel) |
| «SSH login to mini failed» | Server neu gestartet, FileVault gesperrt | `mini-unlock` |
| «The Claude tmux is not running» | Niemand grafisch angemeldet | Per Bildschirmfreigabe anmelden, LaunchAgent startet den Anker |
| «… does not exist on mini» | Projekt nur lokal | `claude-move` oder auf dem Server klonen |
| `loggedIn: false` per SSH | Login fehlt/abgelaufen | Benutzer: `ssh -t mini 'claude auth login'` |
| Alle `ssh mini` hängen | Hängende Master-Verbindung | `ssh -O exit mini`; hängt auch das: `[mux]`-Prozess beenden und Socket `~/.ssh/cm-*` löschen |
| `git push`: Permission denied (publickey) | `Host *` in `~/.ssh/config` setzt einen anderen Agent (z.B. 1Password) | Beim betroffenen Host `IdentityAgent SSH_AUTH_SOCK` ergänzen |

## Grenzen

- Server-Sessions sehen keine lokalen Ressourcen des Laptops (Claude in Chrome, lokales Docker).
  Ausnahme Bilder: Ctrl+V in einem pinken Fenster kopiert ein Bild aus der Laptop-Zwischenablage
  zuerst auf den Server (`~/.dots/tmux/claude-paste.sh`, Kopie in `~/.cache/claude-paste/`), dann
  fügt Claude es dort als [Image #n] ein. Text-Einfügen (Cmd+V) geht ohnehin übers Terminal.
- Zustand und 📡 der Server-Sessions holt `claude-remote.sh poll` regelmässig nach `~/.cache/claude-remote/sessions-<server>`; `claude-status.sh` überträgt sie auf die lokalen Panes (✋/✓, Umschalter, Benachrichtigungen). Cache älter als 30 s = Server nicht erreichbar, dann ohne Zustand.
- Vor Änderungen am Server (sudo, LaunchAgents, Systemeinstellungen) den Benutzer fragen; `sudo` führt er selbst aus.
