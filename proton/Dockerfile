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

# ---------------------------------------------
# Steam Proton image
# ---------------------------------------------
FROM        cm2network/steamcmd:root-bookworm AS base-amd64
FROM        --platform=arm64 sonroyaalmerol/steamcmd-arm64:root-bookworm-2025-04-13 AS base-arm64

ARG         TARGETARCH
FROM        base-${TARGETARCH}

LABEL       author="r3ps4J" maintainer="info@r3ps4j.nl"

LABEL       org.opencontainers.image.source="https://github.com/r3ps4J/steamcmd-yolk"

# Install required packages
RUN         dpkg --add-architecture i386
RUN         apt update
RUN         apt install -y --no-install-recommends \
                wget \
                iproute2 \
                gnupg2 \
                software-properties-common \
                libntlm0 \
                winbind \
                xvfb \
                xauth \
                libncurses5-dev:i386 \
                libncurses6 \
                dbus \
                libgdiplus \
                lib32gcc-s1-amd64-cross
RUN         apt install -y \
                alsa-tools \
                libpulse0 \
                pulseaudio \
                libpulse-dev \
                libasound2 \
                libao-common \
                gnutls-bin \
                gnupg \
                locales \
                cabextract \
                curl \
                python3 \
                python3-pip \
                python3-setuptools \
                tini \
                file \
                pipx

# Download Proton GE
RUN         curl -sLOJ "$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep browser_download_url | cut -d\" -f4 | egrep .tar.gz)"
RUN         tar -xzf GE-Proton*.tar.gz -C /usr/local/bin/ --strip-components=1
RUN         rm GE-Proton*.*

# Proton Fix machine-id
RUN         rm -f /etc/machine-id
RUN         dbus-uuidgen --ensure=/etc/machine-id
RUN         rm /var/lib/dbus/machine-id
RUN         dbus-uuidgen --ensure

# Setup Protontricks
RUN         pipx install protontricks

# Set up Winetricks
RUN	        wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/pelican-eggs/winetricks/master/src/winetricks \
            && chmod +x /usr/sbin/winetricks

# Install rcon
COPY --from=rcon-cli_builder /build/gorcon /usr/bin/rcon

# Setup user and working directory
RUN         useradd -m -d /home/container -s /bin/bash container
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

STOPSIGNAL  SIGINT

COPY        --chown=container:container ./../entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
