FROM golang:1.22.2-alpine as rcon-cli_builder

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

FROM cm2network/steamcmd:root as base-amd64
# Ignoring --platform=arm64 as this is required for the multi-arch build to continue to work on amd64 hosts
# hadolint ignore=DL3029
FROM --platform=arm64 sonroyaalmerol/steamcmd-arm64:root-2024-02-29 as base-arm64

ARG TARGETARCH
# Ignoring the lack of a tag here because the tag is defined in the above FROM lines
# and hadolint isn't aware of those.
# hadolint ignore=DL3006
FROM base-${TARGETARCH} AS container

LABEL maintainer="info@r3ps4j.nl" \
      name="r3ps4j/steamcmd-yolk" \
      github="https://github.com/r3ps4j/steamcmd-yolk" \
      org.opencontainers.image.authors="r3ps4J" \
      org.opencontainers.image.source="https://github.com/r3ps4j/steamcmd-yolk"

# update and install dependencies
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    procps=2:4.0.2-3 \
    wget \ 
    gettext-base=0.21-12 \
    xdg-user-dirs=0.18-1 \
    jo=1.9-1 \
    jq=1.6-2.1 \
    netcat-traditional=1.10-47 \
    iproute2 \
    tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install rcon
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=rcon-cli_builder /build/gorcon /usr/bin/rcon

# Add container user
RUN useradd -m -d /home/container container

# Set user permissions on steam home
RUN chown -R container:container ${STEAMCMDDIR}

# Pass STEAMCMDDIR environment variable to container
ENV STEAMCMDDIR=${STEAMCMDDIR}

# Setting up the user and process
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

STOPSIGNAL SIGINT

COPY --chown=container:container ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD [ "/entrypoint.sh" ]

FROM container AS container-root
USER root

FROM container AS container-proton

USER root
ENV USER=root HOME=/root
WORKDIR /root

## install required packages
RUN dpkg --add-architecture i386
RUN apt update
RUN apt install -y --no-install-recommends wget iproute2 gnupg2 software-properties-common libntlm0 winbind xvfb xauth libncurses5-dev:i386 libncurses6 dbus libgdiplus lib32gcc-s1-amd64-cross
RUN apt install -y alsa-tools libpulse0 pulseaudio libpulse-dev libasound2 libao-common gnutls-bin gnupg locales numactl cabextract curl python3 python3-pip python3-setuptools tini file

# Download Proton GE
RUN curl -sLOJ "$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep browser_download_url | cut -d\" -f4 | egrep .tar.gz)"
RUN tar -xzf GE-Proton*.tar.gz -C /usr/local/bin/ --strip-components=1
RUN rm GE-Proton*.*

# Proton Fix machine-id
RUN rm -f /etc/machine-id
RUN dbus-uuidgen --ensure=/etc/machine-id
RUN rm /var/lib/dbus/machine-id
RUN dbus-uuidgen --ensure

# Set up Protontricks
RUN python3 -m pip install protontricks --break-system-packages

# Set up Winetricks
RUN wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x /usr/sbin/winetricks

USER container
WORKDIR /home/container
