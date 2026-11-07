---
name: dots-publish
description: Änderungen im Dotfiles-Repo ~/.dots committen, auf Öffentliches prüfen, pushen und auf den Mac mini («mini») ausrollen. Verwenden, wenn in ~/.dots committet, gepusht, «veröffentlicht» oder auf den mini synchronisiert werden soll, oder gefragt wird, ob etwas davon nicht öffentlich sein darf.
---

# ~/.dots veröffentlichen

`~/.dots` ist das **öffentliche** GitHub-Repo `jntme/dots` (Branch `master`). Alles, was gepusht wird,
ist für alle sichtbar und bleibt in der Git-Geschichte, auch wenn es später gelöscht wird.

## 1. Prüfen, was rausgeht

```
git -C ~/.dots status --short
git -C ~/.dots diff            # plus `git diff --cached` und neue Dateien ganz lesen
git -C ~/.dots log origin/master..HEAD --stat   # schon committet, noch nicht gepusht
```

Den ganzen Diff lesen (auch Commit-Nachrichten der ungepushten Commits), nicht nur grep. Hilfsweise:

```
git -C ~/.dots diff origin/master | grep -inE '/Users/|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|token|secret|passw|api.?key|@[a-z0-9-]+\.[a-z]'
```

**Darf nicht rein:**
- Firmen-, Kunden-, Personen- und Projektnamen aus der Arbeit (z.B. Ordnernamen unter `~/Claude`,
  Agentennamen, Inhalte aus deren `CLAUDE.md`). In Kommentaren und Readme allgemeine Beispiele
  verwenden (`shop`, `agents/tm`).
- Zugangsdaten jeder Art: Tokens, API-Keys, Passwörter, `.credentials.json`, Schlüsselbund-Inhalte,
  private SSH-Schlüssel, `~/.ssh/config` mit echten Adressen (nur die Vorlage in `macos/`).
- IP-Adressen, echte Hostnamen, Netzwerk-/VPN-Details. `mini` als SSH-Alias ist ok.
- E-Mail-Adressen ausser `mail@jntme.ch` (Autor) und `noreply@anthropic.com` (Co-Author).
- Persönliche Konfigurationen mit Inhalt: `~/.config/claude-remote/projects` liegt bewusst ausserhalb.
- `claude-tmux-setup/` (Moritz' Vorlage) ist in `.gitignore` und bleibt draussen.

Findet sich etwas: nicht committen, dem Benutzer zeigen und fragen. Steckt es schon in einem
ungepushten Commit, den Commit korrigieren, bevor gepusht wird.

## 2. Committen

- Autor: Die repo-lokale `user.email` ist `mail@jntme.ch`. Mit `git -C ~/.dots config user.email` prüfen.
- Nur die betroffenen Dateien gezielt `git add`en (kein `git add -A`).
- Commit-Nachricht auf Deutsch (Schweizer Schreibweise, «ss»): Betreff im Stil `Bereich: was`
  (z.B. `zsh: …`, `tmux: …`, `Switcher: …`), darunter kurz das Warum. Attributionszeilen gemäss
  System-Hinweis anhängen.

## 3. Pushen

Claude darf nicht selbst pushen (Berechtigung verweigert). Den Benutzer bitten, auszuführen:

```
! git -C ~/.dots push origin master
```

Remote ist HTTPS (`gh auth setup-git`). Bei «non-fast-forward»: `git -C ~/.dots fetch` und
`git rebase origin/master`, Konflikte mit dem Benutzer klären, nie `--force`.

## 4. Auf den mini ausrollen

Der mini hat eine eigene Kopie `~/.dots` (gleiche Pfade). Nach dem Push:

```
rsync -a ~/.dots/ mini:.dots/
```

Das kopiert auch `.git`, damit `git status` auf dem mini sauber ist (sein Remote ist SSH, das bleibt).
Vorher kurz Platz prüfen (`ssh mini df -h ~`), ein volles Volume lässt rsync abbrechen.

Danach je nach Änderung:
- `zshrc`: in Shells auf dem mini `reload!` (oder neue Shell); neue SSH-Shells laden sie ohnehin.
- `tmux.conf`: normaler tmux auf dem mini `tmux source ~/.dots/tmux.conf`; lokal ebenso.
- `tmux/server.conf` (Anker `tmux -L claude`): `tmux -L claude source ~/.dots/tmux/server.conf`;
  nie den Anker-Server beenden, darin laufen die Server-Sessions.
- Skripte in `tmux/`: wirken sofort, kein Reload.
- LaunchAgents, `sudo`, Systemeinstellungen: nicht selbst ändern, den Benutzer fragen.

Zum Schluss melden: Commit-Hash, ob GitHub, Laptop und mini auf demselben Stand sind
(`git -C ~/.dots log --oneline -1` lokal und `ssh mini git -C .dots log --oneline -1`).
