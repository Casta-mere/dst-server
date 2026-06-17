FROM ubuntu:22.04

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates lib32gcc-s1 curl libcurl4 \
    && ln -s /usr/lib/x86_64-linux-gnu/libcurl.so.4 /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.4 \
    && ldconfig \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/steamcmd && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
    | tar zxf - -C /opt/steamcmd

# Bust layer cache when DST version changes
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
