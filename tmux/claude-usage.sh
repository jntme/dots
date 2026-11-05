#!/usr/bin/env bash
# Status-bar segment: Claude plan usage of this Mac's account, as /usage shows
# it, e.g. "Session 75% →20:19  Woche 40%  Fable 54%" (percent used).
# Only reads ~/.cache/claude-usage.json; a background refresh from the endpoint
# behind /usage runs at most once a minute, so tmux never waits on the network.

cache=~/.cache/claude-usage.json
stamp=~/.cache/claude-usage.stamp
now=$(date +%s)

if [ $(( now - $(stat -f %m "$stamp" 2>/dev/null || echo 0) )) -ge 60 ]; then
  mkdir -p ~/.cache && touch "$stamp"
  (
    token=$(security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty')
    [ -n "$token" ] || exit 0
    curl -s -m 10 https://api.anthropic.com/api/oauth/usage \
      -H "Authorization: Bearer $token" -H 'anthropic-beta: oauth-2025-04-20' >"$cache.tmp" &&
      jq -e '.limits' "$cache.tmp" >/dev/null 2>&1 && mv "$cache.tmp" "$cache"
    rm -f "$cache.tmp"
  ) >/dev/null 2>&1 &
fi

# Older than 10 minutes = token expired or offline: show nothing rather than stale numbers
[ -f "$cache" ] && [ $(( now - $(stat -f %m "$cache") )) -lt 600 ] || exit 0

jq -r '
  def color: if . >= 80 then "colour203" elif . >= 50 then "colour214" else "colour245" end;
  def localtime: sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdate | strflocaltime("%H:%M");
  [ .limits[]
    | (if .group == "session" then "Session"
       elif .scope.model.display_name then .scope.model.display_name
       else "Woche" end) as $label
    | "#[fg=colour243]\($label) #[fg=\(.percent | color)]\(.percent)%"
      + (if .group == "session" and .resets_at then "#[fg=colour240] →\(.resets_at | localtime)" else "" end)
  ] | join("  ") | if . != "" then . + " " else . end
' "$cache" 2>/dev/null
