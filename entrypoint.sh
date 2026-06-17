#!/bin/bash
set -e

SHARD=${SHARD:-Master}
CLUSTER_NAME=${CLUSTER_NAME:-MyCluster}
DATA_DIR=${DATA_DIR:-/data}
FIFO=/tmp/dst.in

# Link bind-mounted mods dir so server finds it
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

/opt/dst/bin64/dontstarve_dedicated_server_nullrenderer_x64 \
    -console \
    -cluster "$CLUSTER_NAME" \
    -shard "$SHARD" \
    -persistent_storage_root "$DATA_DIR" \
    < "$FIFO" &
PID=$!
wait "$PID"
