#!/usr/bin/env bash
set -uo pipefail

: "${NOWPLAYING_SERVER:?NOWPLAYING_SERVER must be set}"
: "${NOWPLAYING_TOKEN_FILE:?NOWPLAYING_TOKEN_FILE must be set}"

server="$NOWPLAYING_SERVER"
token_file="$NOWPLAYING_TOKEN_FILE"
min_play_seconds="${NOWPLAYING_MIN_PLAY_SECONDS:-15}"

if [ ! -r "$token_file" ]; then
  echo "error: cannot read token file: $token_file" >&2
  exit 1
fi
token="$(tr -d '\r\n' < "$token_file")"
case "$token" in
  NOWPLAYING_TOKEN=*) token="${token#NOWPLAYING_TOKEN=}" ;;
esac

post() {
  local listen_type="$1"
  local payload="$2"
  if ! curl -fsS --connect-timeout 3 --max-time 8 -X POST "$server/1/submit-listens" \
    -H "Authorization: Token $token" \
    -H "Content-Type: application/json" \
    --data-binary "{\"listen_type\":\"$listen_type\",\"payload\":[$payload]}" \
    >/dev/null 2>&1; then
    echo "nowplaying: failed to POST $listen_type to $server" >&2
  fi
}

sep=$'\x1f'

nowplaying_payload() {
  jq -nc \
    --arg player "$player" \
    --arg artist "$artist" \
    --arg title "$title" \
    --arg album "$album" \
    --argjson duration "$duration" \
    --arg url "$url" \
    '{
      track_metadata: {
        artist_name: $artist,
        track_name: $title,
        release_name: (if $album != "" then $album else null end),
        additional_info: {
          duration: (if $duration > 0 then $duration else null end),
          music_service_name: $player,
          media_player: $player,
          origin_url: (if $url != "" then $url else null end)
        }
      }
    }'
}

scrobble_payload() {
  jq -nc \
    --argjson listened_at "$prev_start" \
    --arg player "$prev_player" \
    --arg artist "$prev_artist" \
    --arg title "$prev_title" \
    --arg album "$prev_album" \
    --argjson duration "$prev_duration" \
    --arg url "$prev_url" \
    '{
      listened_at: $listened_at,
      track_metadata: {
        artist_name: $artist,
        track_name: $title,
        release_name: (if $album != "" then $album else null end),
        additional_info: {
          duration: (if $duration > 0 then $duration else null end),
          music_service_name: $player,
          media_player: $player,
          origin_url: (if $url != "" then $url else null end)
        }
      }
    }'
}

prev_player=""
prev_artist=""
prev_title=""
prev_album=""
prev_duration=0
prev_url=""
prev_start=0

while :; do
  playerctl --follow metadata --format \
    "{{playerName}}${sep}{{status}}${sep}{{artist}}${sep}{{title}}${sep}{{album}}${sep}{{mpris:length}}${sep}{{xesam:url}}" \
    || true
  sleep 5
done | while IFS="$sep" read -r player status artist title album length_us url; do
  [ -z "$title" ] && continue

  now="$(date +%s)"
  duration=0
  [ -n "$length_us" ] && duration=$((length_us / 1000000))

  if [ "$status" = "Playing" ] && { [ "$player" != "$prev_player" ] || [ "$title" != "$prev_title" ]; }; then
    if [ -n "$prev_title" ] && [ $((now - prev_start)) -ge "$min_play_seconds" ]; then
      post single "$(scrobble_payload)"
    fi
    post playing_now "$(nowplaying_payload)"
    prev_player="$player"
    prev_artist="$artist"
    prev_title="$title"
    prev_album="$album"
    prev_duration="$duration"
    prev_url="$url"
    prev_start="$now"
  fi
done
