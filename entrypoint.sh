#!/bin/bash
set -e

DST_BIN=/opt/dst/bin64/dontstarve_dedicated_server_nullrenderer_x64
SHARD=${SHARD:-Master}
CLUSTER_NAME=${CLUSTER_NAME:-MyCluster}
DATA_DIR=${DATA_DIR:-/data}
FIFO=/tmp/dst.in

# Patch ELF DYNAMIC segment to drop version requirements (DT_VERNEED/VERSYM).
# Lets the binary load system libcurl.so.4 via the libcurl-gnutls.so.4 symlink.
# Idempotent — safe to run every start; re-applies automatically after DST updates.
python3 /patch_elf.py "$DST_BIN"

# Replace game's mods dir with symlink to the user-managed mods volume.
[ -d /opt/dst/mods ] && [ ! -L /opt/dst/mods ] && rm -rf /opt/dst/mods
ln -sfn /mods /opt/dst/mods

rm -f "$FIFO"
mkfifo "$FIFO"
sleep infinity > "$FIFO" &
HOLD=$!

graceful_stop() {
    echo "c_save()" > "$FIFO"
    sleep 5
    echo "c_shutdown()" > "$FIFO"
    wait "$PID" 2>/dev/null || true
    kill "$HOLD" 2>/dev/null || true
}
trap graceful_stop SIGTERM SIGINT

cd /opt/dst/data
"$DST_BIN" \
    -console \
    -cluster "$CLUSTER_NAME" \
    -shard "$SHARD" \
    -persistent_storage_root "$DATA_DIR" \
    < "$FIFO" &
PID=$!
wait "$PID"
