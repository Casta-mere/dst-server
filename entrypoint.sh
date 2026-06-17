#!/bin/bash
set -e

DST_BIN=/opt/dst/bin64/dontstarve_dedicated_server_nullrenderer_x64
SHARD=${SHARD:-Master}
CLUSTER_NAME=${CLUSTER_NAME:-MyCluster}
DATA_DIR=${DATA_DIR:-/data}
FIFO=/tmp/dst.in

# Patch DST binary to use system libcurl. Idempotent — safe to run every start.
# patchelf: redirect libcurl-gnutls.so.4 -> libcurl.so.4 in DT_NEEDED
# objcopy: remove both version sections (.gnu.version references .gnu.version_r;
#          removing only one leaves the ELF in an inconsistent state)
patchelf --replace-needed libcurl-gnutls.so.4 libcurl.so.4 "$DST_BIN" 2>/dev/null || true
objcopy --remove-section .gnu.version --remove-section .gnu.version_r "$DST_BIN" 2>/dev/null || true

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

"$DST_BIN" \
    -console \
    -cluster "$CLUSTER_NAME" \
    -shard "$SHARD" \
    -persistent_storage_root "$DATA_DIR" \
    < "$FIFO" &
PID=$!
wait "$PID"
