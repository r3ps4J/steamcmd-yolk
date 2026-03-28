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
# Bookworm steamcmd as that is what 22.04 is based on
FROM cm2network/steamcmd:root-bookworm AS steamcmd

# Use the official Ubuntu 22.04 as the base image
FROM ubuntu:22.04 AS base

# Create user
RUN useradd -m -d /home/container -s /bin/bash container
# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

FROM base AS base-amd64

# 32-bit libraries only needed on amd64
RUN apt update \
    && apt upgrade -y \
    && apt install -y \
        lib32gcc-s1 \
        lib32stdc++6 \
        lib32tinfo6 \
        lib32z1

ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]

FROM --platform=arm64 base AS base-arm64

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    cmake \
    ninja-build \
    pkg-config \
    ccache \
    # Recommended if you're rebuilding constantly
    clang \
    llvm \
    # For ThinLTO
    lld \
    # For AArch64 binfmt_misc support
    binfmt-support \
    libsdl2-dev \
    libepoxy-dev \
    libssl-dev \
    # For build scripts
    python3-setuptools \
    # For building thunks
    g++-x86-64-linux-gnu \
    nasm \
    # For struct verifier
    python3-clang \
    # For struct verifier
    libstdc++-12-dev-i386-cross \
    # For struct verifier
    libstdc++-12-dev-amd64-cross \
    # For struct verifier
    libstdc++-12-dev-arm64-cross \
    # For squashfs rootfs support
    squashfs-tools \
    # For mounting the squashfs
    squashfuse \
    # For unittests, needs catchsegv from this
    libc-bin \
    # FEXConfig GUI
    qtdeclarative5-dev \
    # etc
    expect \
    curl \
    sudo \
    fuse

# Create a new user and set their home directory
RUN useradd -m -s /bin/bash fex

RUN usermod -aG sudo fex

RUN echo "fex ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/fex

USER fex

WORKDIR /home/fex

# Clone the FEX repository and build it
RUN git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git && \
    cd FEX && \
    mkdir Build && \
    cd Build && \
    CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTING=False -DENABLE_ASSERTIONS=False -DUSE_LEGACY_BINFMTMISC=True -G Ninja .. && \
    ninja

WORKDIR /home/fex/FEX/Build

RUN sudo ninja install && \
    sudo ninja binfmt_misc

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    jq \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER container

# Set up rootfs
# Download FEX rootfs dynamically using jq
RUN mkdir -p /home/container/.fex-emu/RootFS \
    && ROOTFS_URL=$(curl -s https://rootfs.fex-emu.gg/RootFS_links.json | \
    jq -r '.v1 | to_entries[] | select(.value.DistroMatch == "ubuntu" and .value.DistroVersion == "24.04" and .value.Type == "squashfs") | .value.URL') \
    && echo "Downloading RootFS from: $ROOTFS_URL" \
    && curl -L -o /home/container/.fex-emu/RootFS/Ubuntu_24_04.sqsh "$ROOTFS_URL" \
    && echo '{"Config":{"RootFS":"Ubuntu_24_04.sqsh"}}' > /home/container/.fex-emu/Config.json

ENTRYPOINT  ["/usr/bin/tini", "-g", "--", "FEXBash"]

## Beginning of common steps
ARG         TARGETARCH
FROM        base-${TARGETARCH}

LABEL       author="r3ps4J" maintainer="info@r3ps4j.nl"

LABEL       org.opencontainers.image.source="https://github.com/r3ps4J/steamcmd-yolk"

USER        root
WORKDIR     /

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
                libncurses5-dev \
                libncurses6 \
                dbus \
                libgdiplus
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

# Install steamcmd
COPY --from=steamcmd /home/steam /home/steam
ENV STEAMCMDDIR=/home/steam/steamcmd
# skips Steam's bash script from checking for glibc and throwing a warning window 
ENV     STEAMOS=1
ENV     STEAM_RUNTIME=1
# fixes some games crashing from a dbus bug
ENV     DBUS_FATAL_WARNINGS=0

# Setup user and working directory
USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

STOPSIGNAL  SIGINT

COPY        --chown=container:container ./../entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh
# Entrypoint is set above for multi-arch support
# ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
