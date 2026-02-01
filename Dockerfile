FROM cm2network/steamcmd:root-bookworm AS base-amd64
FROM --platform=arm64 sonroyaalmerol/steamcmd-arm64:root-bookworm-2025-04-13 AS base-arm64

ARG TARGETARCH
# Native build
FROM base-${TARGETARCH} AS container

LABEL maintainer="info@r3ps4j.nl" \
      name="r3ps4j/steamcmd-yolk" \
      github="https://github.com/r3ps4j/steamcmd-yolk" \
      org.opencontainers.image.authors="r3ps4J" \
      org.opencontainers.image.source="https://github.com/r3ps4j/steamcmd-yolk"

ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
    && apt update \
    && apt upgrade -y \
    && apt install -y \
        curl \
        g++ \
        gcc \
        gdb \
        iproute2 \
        locales \
        numactl \
        net-tools \
        netcat-traditional \
        tar \
        telnet \
        tini \
        tzdata \
        wget \
        xvfb \
        lib32gcc-s1-amd64-cross \
        lib32stdc++6 \
        lib32tinfo6 \
        lib32z1 \
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
RUN cd /tmp/ \
    && curl -sSL https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz > rcon.tar.gz \
    && tar xvf rcon.tar.gz \
    && mv rcon-0.10.3-amd64_linux/rcon /usr/local/bin/


# Temp fix for things that still need libssl1.1
RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
    dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb && \
    rm libssl1.1_1.1.0g-2ubuntu4_amd64.deb;

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Setup user and working directory
RUN useradd -m -d /home/container -s /bin/bash container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

STOPSIGNAL SIGINT

COPY --chown=container:container ../entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]

FROM container AS container-root

USER root
ENV USER=root HOME=/root

RUN chown -R root:root ${STEAMCMDDIR}

# Proton build
FROM base-${TARGETARCH} AS container-proton

# Install required packages
RUN dpkg --add-architecture i386
RUN apt update
RUN apt install -y --no-install-recommends \
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
RUN apt install -y \
    alsa-tools \
    libpulse0 \
    pulseaudio \
    libpulse-dev \
    libasound2 \
    libao-common \
    gnutls-bin \
    gnupg \
    locales \
    numactl \
    cabextract \
    curl \
    python3 \
    python3-pip \
    python3-setuptools \
    tini \
    file \
    pipx

# Download Proton GE
RUN curl -sLOJ "$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep browser_download_url | cut -d\" -f4 | egrep .tar.gz)"
RUN tar -xzf GE-Proton*.tar.gz -C /usr/local/bin/ --strip-components=1
RUN rm GE-Proton*.*

# Proton Fix machine-id
RUN rm -f /etc/machine-id
RUN dbus-uuidgen --ensure=/etc/machine-id
RUN rm /var/lib/dbus/machine-id
RUN dbus-uuidgen --ensure

# Setup Protontricks
RUN pipx install protontricks

# Set up Winetricks
RUN	wget -q -O /usr/sbin/winetricks https://raw.githubusercontent.com/pelican-eggs/winetricks/master/src/winetricks \
    && chmod +x /usr/sbin/winetricks

# Install rcon
RUN cd /tmp/ \
    && curl -sSL https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-amd64_linux.tar.gz > rcon.tar.gz \
    && tar xvf rcon.tar.gz \
    && mv rcon-0.10.3-amd64_linux/rcon /usr/local/bin/
            
# Setup user and working directory
RUN useradd -m -d /home/container -s /bin/bash container
USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

STOPSIGNAL SIGINT

COPY --chown=container:container ./../entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
