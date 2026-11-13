ARG BUILD_FROM=mikebrady/shairport-sync:5.6.3
FROM ${BUILD_FROM}

# shairport-sync image is Alpine; add what the bridge needs (FLAC encoding + options parsing)
RUN apk add --no-cache python3 ffmpeg jq \
    && LD_LIBRARY_PATH=/usr/lib:/lib ffmpeg -hide_banner -version > /dev/null

COPY server.py /app/server.py
COPY shairport-sync.conf /etc/shairport-sync.conf.template
COPY --chmod=755 run.sh /run-app.sh

ENTRYPOINT ["/run-app.sh"]
