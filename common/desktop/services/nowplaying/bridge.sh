#!/usr/bin/env bash
set -uo pipefail

: "${NOWPLAYING_SERVER:?NOWPLAYING_SERVER must be set}"
: "${NOWPLAYING_TOKEN_FILE:?NOWPLAYING_TOKEN_FILE must be set}"

server="$NOWPLAYING_SERVER"
token_file="$NOWPLAYING_TOKEN_FILE"
min_play_seconds="${NOWPLAYING_MIN_PLAY_SECONDS:-15}"
heartbeat_seconds="${NOWPLAYING_HEARTBEAT_SECONDS:-30}"
state_file="${XDG_RUNTIME_DIR:-/tmp}/nowplaying-bridge-state"

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

mk_payload() {
  local paused="$1"
  local stopped="$2"
  local position="$3"
  jq -nc \
    --arg player "$player" \
    --arg artist "$artist" \
    --arg title "$title" \
    --arg album "$album" \
    --argjson duration "$duration" \
    --arg url "$url" \
    --argjson paused "$paused" \
    --argjson stopped "$stopped" \
    --argjson position "$position" \
    '{
      track_metadata: {
        artist_name: $artist,
        track_name: $title,
        release_name: (if $album != "" then $album else null end),
        additional_info: {
          duration: (if $duration > 0 then $duration else null end),
          music_service_name: $player,
          media_player: $player,
          origin_url: (if $url != "" then $url else null end),
          paused: $paused,
          stopped: $stopped,
          position: (if $position >= 0 then $position else null end)
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

write_state() {
  printf '%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\x1f%s\n' \
    "$prev_player" "$prev_status" "$prev_artist" "$prev_title" \
    "$prev_album" "$prev_duration" "$prev_url" > "$state_file"
}

clear_state() {
  rm -f "$state_file"
}

heartbeat() {
  while :; do
    sleep "$heartbeat_seconds"
    [ -s "$state_file" ] || continue
    IFS="$sep" read -r hb_player hb_status hb_artist hb_title hb_album hb_duration hb_url < "$state_file"
    [ -n "$hb_title" ] || continue

    status_now="$(playerctl -p "$hb_player" status 2>/dev/null)" || {
      player="$hb_player"
      artist="$hb_artist"
      title="$hb_title"
      album="$hb_album"
      duration="$hb_duration"
      url="$hb_url"
      post playing_now "$(mk_payload false true -1)"
      clear_state
      continue
    }

    pos_secs=-1
    if pos_us="$(playerctl -p "$hb_player" position 2>/dev/null || true)"; then
      case "$pos_us" in
        *[0-9]*) pos_secs="${pos_us%%.*}" ;;
      esac
    fi

    player="$hb_player"
    artist="$hb_artist"
    title="$hb_title"
    album="$hb_album"
    duration="$hb_duration"
    url="$hb_url"
    if [ "$status_now" = "Paused" ]; then
      post playing_now "$(mk_payload true false "$pos_secs")"
    else
      post playing_now "$(mk_payload false false "$pos_secs")"
    fi
  done
}
heartbeat &
HB_PID=$!

prev_player=""
prev_artist=""
prev_title=""
prev_album=""
prev_duration=0
prev_url=""
prev_start=0
prev_status=""
played_seconds=0

while :; do
  playerctl --follow metadata --format \
    "{{playerName}}${sep}{{status}}${sep}{{artist}}${sep}{{title}}${sep}{{album}}${sep}{{mpris:length}}${sep}{{xesam:url}}${sep}{{position}}" \
    || true
  sleep 5
done | while IFS="$sep" read -r player status artist title album length_us url position_us; do
  [ -z "$title" ] && [ "$status" != "Stopped" ] && continue

  now="$(date +%s)"
  duration=0
  [ -n "$length_us" ] && duration=$((length_us / 1000000))
  position=-1
  [ -n "$position_us" ] && position=$((position_us / 1000000))

  if [ "$status" = "Playing" ]; then
    if [ "$player" != "$prev_player" ] || [ "$title" != "$prev_title" ]; then
      played="$played_seconds"
      if [ "$prev_status" = "Playing" ]; then
        played=$((played + now - prev_start))
      fi
      if [ -n "$prev_title" ] && [ "$played" -ge "$min_play_seconds" ]; then
        post single "$(scrobble_payload)"
      fi
      post playing_now "$(mk_payload false false "$position")"
      prev_player="$player"
      prev_artist="$artist"
      prev_title="$title"
      prev_album="$album"
      prev_duration="$duration"
      prev_url="$url"
      prev_start="$now"
      prev_status="Playing"
      played_seconds=0
      write_state
    elif [ "$prev_status" = "Paused" ]; then
      post playing_now "$(mk_payload false false "$position")"
      prev_start="$now"
      prev_status="Playing"
      write_state
    fi
  elif [ "$status" = "Paused" ] &&
    [ "$prev_status" = "Playing" ] &&
    [ "$player" = "$prev_player" ] &&
    [ "$title" = "$prev_title" ]; then
    played_seconds=$((played_seconds + now - prev_start))
    prev_start="$now"
    prev_status="Paused"
    post playing_now "$(mk_payload true false "$position")"
    write_state
  elif [ "$status" = "Stopped" ] && [ "$player" = "$prev_player" ] && [ -n "$prev_title" ]; then
    played="$played_seconds"
    if [ "$prev_status" = "Playing" ]; then
      played=$((played + now - prev_start))
    fi
    if [ "$played" -ge "$min_play_seconds" ]; then
      post single "$(scrobble_payload)"
    fi
    player="$prev_player"
    artist="$prev_artist"
    title="$prev_title"
    album="$prev_album"
    duration="$prev_duration"
    url="$prev_url"
    post playing_now "$(mk_payload false true -1)"
    prev_player=""
    prev_artist=""
    prev_title=""
    prev_album=""
    prev_duration=0
    prev_url=""
    prev_start=0
    prev_status=""
    played_seconds=0
    clear_state
  fi
done
