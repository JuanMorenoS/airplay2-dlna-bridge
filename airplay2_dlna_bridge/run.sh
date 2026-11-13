#!/bin/sh
# Home Assistant app entrypoint: read /data/options.json, start the bridge,
# then hand over to the stock shairport-sync image entrypoint (avahi + nqptp).
set -e

OPTIONS=/data/options.json
opt() { jq -r ".$1" "$OPTIONS"; }

AIRPLAY_NAME="$(opt airplay_name)"
RENDERER_IP="$(opt renderer_ip)"
HOST_IP="$(opt host_ip)"
STREAM_PORT="$(opt stream_port)"
MAX_VOLUME="$(opt max_volume)"
if [ "$(opt didl_push)" = "true" ]; then DIDL_PUSH=1; else DIDL_PUSH=0; fi

if [ -z "$HOST_IP" ]; then
  # first IPv4 of the default route interface (the app runs on the host network)
  HOST_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p')"
fi
if [ -z "$HOST_IP" ]; then
  echo "host_ip is empty and could not be detected; set it in the app options" >&2
  exit 1
fi

export AUDIO_PIPE=/tmp/shared/audio
export META_PIPE=/tmp/shared/metadata
export RENDERER_IP STREAM_PORT MAX_VOLUME DIDL_PUSH
export STREAM_URL="http://${HOST_IP}:${STREAM_PORT}/stream.flac"
export FLUSH_RESYNC=0

sed "s#__AIRPLAY_NAME__#${AIRPLAY_NAME}#" /etc/shairport-sync.conf.template > /etc/shairport-sync.conf

echo "AirPlay name: ${AIRPLAY_NAME}; renderer: ${RENDERER_IP:-<none>}; stream: ${STREAM_URL}"

# bridge first: it creates the FIFOs shairport-sync writes to; restart it if it dies
( while true; do python3 -u /app/server.py || true; echo "bridge exited, restarting in 2 s"; sleep 2; done ) &

for _ in $(seq 1 30); do
  [ -p "$AUDIO_PIPE" ] && [ -p "$META_PIPE" ] && break
  sleep 1
done

cd /
exec ./run.sh -c /etc/shairport-sync.conf
