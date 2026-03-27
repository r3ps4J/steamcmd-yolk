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

# Bookworm steamcmd as that is what 22.04 is based on
FROM cm2network/steamcmd:root-bookworm AS steamcmd

# Use the official Ubuntu 22.04 as the base image
FROM ubuntu:22.04 AS base
# Create user
RUN useradd -m -d /home/container -s /bin/bash container

FROM base AS base-amd64
ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]

FROM --platform=arm64 base AS base-arm64

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    cmake \
    ninja-build \
    pkg-config \
    ccache \
    clang \
    llvm \
    lld \
    binfmt-support \
    libsdl2-dev \
    libepoxy-dev \
    libssl-dev \
    python3-setuptools \
    g++-x86-64-linux-gnu \
    nasm \
    python3-clang \
    libstdc++-12-dev-i386-cross \
    libstdc++-12-dev-amd64-cross \
    libstdc++-12-dev-arm64-cross \
    squashfs-tools \
    squashfuse \
    libc-bin \
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
    CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTING=False -DENABLE_ASSERTIONS=False -G Ninja .. && \
    ninja

WORKDIR /home/fex/FEX/Build

RUN sudo ninja install && \
    sudo ninja binfmt_misc_32 && \
    sudo ninja binfmt_misc_64

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

ENV         DEBIAN_FRONTEND=noninteractive

RUN         apt update \
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
                lib32gcc-s1 \
                lib32stdc++6 \
                lib32tinfo6 \
                lib32z1 \
                libcurl3-gnutls \
                libcurl4-gnutls-dev \
                libcurl4 \
                libfontconfig1 \
                libgcc-11-dev \
                libgcc-12-dev \
                libncurses5 \
                libsdl1.2debian \
                libsdl2-2.0-0 \
                libssl-dev \
                libtinfo6

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
