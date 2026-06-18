#!/bin/bash
# DST auto-update: checks for new build, updates game files, restarts if changed.
# Reads current build ID from steamapps manifest to avoid unnecessary restarts.

set -euo pipefail

GAME_DIR=/volume3/Dev/dst/game
COMPOSE_DIR=/volume3/Dev/dst-server
MANIFEST="$GAME_DIR/steamapps/appmanifest_343050.acf"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

CURRENT_BUILD=$(grep -oP '"buildid"\s+"\K[^"]+' "$MANIFEST" 2>/dev/null || echo "unknown")
log "Current build: $CURRENT_BUILD — running steamcmd update check..."

docker run --rm \
  -v "$GAME_DIR:/opt/dst" \
  ubuntu:22.04 \
  bash -c "
    dpkg --add-architecture i386 && apt-get update -qq &&
    apt-get install -y --no-install-recommends lib32gcc-s1 ca-certificates curl &&
    mkdir -p /opt/steamcmd &&
    curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar xz -C /opt/steamcmd &&
    /opt/steamcmd/steamcmd.sh \
      +@sSteamCmdForcePlatformType linux \
      +@sSteamCmdForcePlatformBitness 64 \
      +force_install_dir /opt/dst \
      +login anonymous \
      +app_update 343050 \
      +quit
  "

NEW_BUILD=$(grep -oP '"buildid"\s+"\K[^"]+' "$MANIFEST" 2>/dev/null || echo "unknown")

if [ "$CURRENT_BUILD" = "$NEW_BUILD" ]; then
  log "Already up to date (build $CURRENT_BUILD). No restart needed."
  exit 0
fi

log "Updated $CURRENT_BUILD → $NEW_BUILD. Restarting servers..."
cd "$COMPOSE_DIR"
docker compose stop dst-master dst-caves
docker compose start dst-master dst-caves
log "Done. Servers running build $NEW_BUILD."
