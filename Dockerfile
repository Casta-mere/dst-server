# Stage 1: extract GnuTLS-flavoured libcurl from Debian buster
# (buster is the last release that ships libcurl4-gnutls as a runtime package)
FROM debian:buster-slim AS gnutls
RUN apt-get update && \
    apt-get install -y --no-install-recommends libcurl4-gnutls && \
    rm -rf /var/lib/apt/lists/*

# Stage 2: actual server image
FROM ubuntu:22.04

# Copy the real GnuTLS libcurl (with CURL_GNUTLS_3 symbol) from buster
COPY --from=gnutls /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.4* /usr/lib/x86_64-linux-gnu/

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates lib32gcc-s1 curl \
    && ldconfig \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/steamcmd && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
    | tar zxf - -C /opt/steamcmd

ARG DST_BUILD_ID=unknown
RUN /opt/steamcmd/steamcmd.sh \
        +@sSteamCmdForcePlatformType linux \
        +@sSteamCmdForcePlatformBitness 64 \
        +force_install_dir /opt/dst \
        +login anonymous \
        +app_update 343050 validate \
        +quit

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/data", "/mods"]

ENTRYPOINT ["/entrypoint.sh"]
