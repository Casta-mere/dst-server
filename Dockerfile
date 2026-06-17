FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
        libcurl4 lib32gcc-s1 python3 ca-certificates \
    && ln -s /usr/lib/x86_64-linux-gnu/libcurl.so.4 \
             /usr/lib/x86_64-linux-gnu/libcurl-gnutls.so.4 \
    && ldconfig \
    && rm -rf /var/lib/apt/lists/*

COPY patch_elf.py /patch_elf.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
