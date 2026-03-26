FROM golang:1.22.2-alpine AS rcon-cli_builder

ARG RCON_VERSION="0.10.3"
ARG RCON_TGZ_SHA1SUM=33ee8077e66bea6ee097db4d9c923b5ed390d583

WORKDIR /build

# install rcon
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

ENV CGO_ENABLED=0
RUN wget -q https://github.com/gorcon/rcon-cli/archive/refs/tags/v${RCON_VERSION}.tar.gz -O rcon.tar.gz \
    && echo "${RCON_TGZ_SHA1SUM}" rcon.tar.gz | sha1sum -c - \
    && tar -xzvf rcon.tar.gz \
    && rm rcon.tar.gz \
    && mv rcon-cli-${RCON_VERSION}/* ./ \
    && rm -rf rcon-cli-${RCON_VERSION} \
    && go build -v ./cmd/gorcon

FROM        cm2network/steamcmd:root-bookworm AS steamcmd

FROM ubuntu:24.04 AS fex_builder

ENV DEBIAN_FRONTEND=noninteractive

# Install only build-time dependencies with --no-install-recommends
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    jq \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download FEX rootfs dynamically using jq
RUN mkdir -p /root/.fex-emu/RootFS \
    && ROOTFS_URL=$(curl -s https://rootfs.fex-emu.gg/RootFS_links.json | \
    jq -r '.v1 | to_entries[] | select(.value.DistroMatch == "ubuntu" and .value.DistroVersion == "22.04" and .value.Type == "squashfs") | .value.URL') \
    && echo "Downloading RootFS from: $ROOTFS_URL" \
    && curl -L -o /root/.fex-emu/RootFS/Ubuntu_22_04.sqsh "$ROOTFS_URL" \
    && echo '{"Config":{"RootFS":"Ubuntu_22_04.sqsh"}}' > /root/.fex-emu/Config.json

FROM        ubuntu:22.04 AS base
# Create user
RUN         useradd -m -d /home/container -s /bin/bash container

FROM        base AS base-amd64
ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]

FROM        --platform=arm64 base AS base-arm64

ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime dependencies with --no-install-recommends
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    gnupg \
    fuse3 \
    && add-apt-repository -y ppa:fex-emu/fex \
    && apt-get update && apt-get install -y --no-install-recommends \
    fex-emu-armv8.0 \
    fex-emu-binfmt32 \
    fex-emu-binfmt64 || true \
    && apt-get purge -y --auto-remove software-properties-common gnupg || true \
    && apt-get clean || true \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archives/* \
    && update-binfmts --enable \
    && install -d -m 0775 -o root -g container /opt/.fex-emu \
    && ln -s /opt/.fex-emu /home/container/.fex-emu

# Copy from builder stage
COPY --chmod=775 --chown=root:container --from=fex_builder /root/.fex-emu /opt/.fex-emu

ENV PATH="/root/.local/bin:${PATH}"

ENTRYPOINT  ["/usr/bin/tini", "-g", "--", "FEXBash"]

ARG         TARGETARCH
FROM        base-${TARGETARCH}

LABEL       author="r3ps4J" maintainer="info@r3ps4j.nl"

LABEL       org.opencontainers.image.source="https://github.com/r3ps4J/steamcmd-yolk"

ENV         DEBIAN_FRONTEND=noninteractive

RUN         dpkg --add-architecture i386 \
            && apt update \
            && apt upgrade -y \
            && apt install -y \
                curl \
                g++ \
                gcc \
                gdb \
                iproute2 \
                locales \
                net-tools \
                netcat-traditional \
                tar \
                telnet \
                tini \
                tzdata \
                wget \
                xvfb \
                lib32gcc-s1-amd64-cross \
                lib32stdc++6-amd64-cross \
                libcurl3-gnutls:i386 \
                libcurl4-gnutls-dev:i386 \
                libcurl4:i386 \
                libfontconfig1 \
                libgcc-11-dev \
                libgcc-12-dev \
                libncurses5:i386 \
                libsdl1.2debian \
                libsdl2-2.0-0 \
                libsdl2-2.0-0:i386 \
                libssl-dev:i386 \
                libtinfo6:i386

# Install rcon
COPY --from=rcon-cli_builder /build/gorcon /usr/bin/rcon

# Install steamcmd
COPY --from=steamcmd /home/steam /home/steam
ENV STEAMCMDDIR=/home/steam/steamcmd

# Temp fix for things that still need libssl1.1
RUN         if [ "$(uname -m)" = "x86_64" ]; then \
                wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
                dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
                rm libssl1.1_1.1.0g-2ubuntu4_amd64.deb; \
            fi

# Set the locale
RUN         sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
            locale-gen
ENV         LANG=en_US.UTF-8
ENV         LANGUAGE=en_US:en
ENV         LC_ALL=en_US.UTF-8

# Setup user and working directory
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

STOPSIGNAL  SIGINT

COPY        --chown=container:container ../entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
# Entrypoint is set above for multi-arch support
# ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
