FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
        libcurl4 lib32gcc-s1 patchelf binutils ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
