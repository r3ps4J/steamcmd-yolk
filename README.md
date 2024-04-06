# steamcmd-yolk

A pterodactyl yolk for hosting steamcmd servers on amd64 and arm64 based on [palworld-server-docker](https://github.com/thijsvanloef/palworld-server-docker/) by [thijsvanloef](https://github.com/thijsvanloef) and the [steamcmd yolk](https://github.com/parkervcp/yolks/blob/master/steamcmd/) by [parkervcp](https://github.com/parkervcp).

## arm64

Arm64 compatibility is done through box86 and box64 thanks to the [steamcmd-arm64 image](https://github.com/sonroyaalmerol/steamcmd-arm64) by [sonroyaalmerol](https://github.com/sonroyaalmerol). This is a drop-in replacement for [cm2network/steamcmd](https://github.com/CM2Walki/steamcmd/), which is used for amd64.

For some servers this image might be unstable. If you experience this I recommend taking a look at [QuintenQVD0](https://github.com/QuintenQVD0)'s [Q_eggs repository](https://github.com/QuintenQVD0/Q_eggs). He has created eggs that run with the FEX emulator instead.

FEX can run more stable, based on my own experience, but is also a bit slower. It also requires you to download a RootFS which can take up a lot of space. For a more detailed comparison between emulators I recommend reading this arcticle by the creator of box86 and box64: https://box86.org/2022/03/box86-box64-vs-qemu-vs-fex-vs-rosetta2/.

## Usage

You can use this yolk like any other yolk. Note that steamcmd is already installed in /home/steam/steamcmd. You can use the `STEAMCMDDIR` environment variable to get the right path.

Use `${STEAMCMDDIR}/steamcmd.sh` to use steamcmd, for example:

```bash
${STEAMCMDDIR}/steamcmd.sh +force_install_dir /mnt/server +login anonymous +app_update ${SRCDS_APPID} validate +exit
```

This image doesn't work well by just running it without an installation script. I don't know why, but just install the game through an installation script if you make an egg based on this. Running this image outside of pterodactyl does not require an installation script.

## Variants

There is a variant of the image available with `root` set as the default user. This was mainly done in order to use it as install script container for pterodactyl, but you might find it useful if you are running this image outside of pterodactyl and need root access.

There is also a variant of the image with proton support. This is based on the `steamcmd:proton` image by parkervcp. It is used for games that only have a windows server available.

## Available tags

The available tags are:

Normal image:
- `latest` latest version.
- `v{{major}}` latest version within a specific major version.
- `v{{major}}.{{minor}}` latest version within a specific major and minor version.
- `v{{major}}.{{minor}}.{{patch}}` specific version.
- `dev` latest commit.

With root as default user:
- `root` latest version.
- `root-v{{major}}` latest version within a specific major version.
- `root-v{{major}}.{{minor}}` latest version within a specific major and minor version.
- `root-v{{major}}.{{minor}}.{{patch}}` specific version.
- `root-dev` latest commit.

With proton support:
- `proton` latest version.
- `proton-v{{major}}` latest version within a specific major version.
- `proton-v{{major}}.{{minor}}` latest version within a specific major and minor version.
- `proton-v{{major}}.{{minor}}.{{patch}}` specific version.
- `proton-dev` latest commit.

## Drop-in replacement

This yolk can be used as a drop-in replacement for parkervcp's `games:source`, `steamcmd` and `steamcmd:proton` yolks. In order to use it you will have to do 2 things.

1. Add `ghcr.io/r3ps4j/steamcmd-yolk:latest` (or `ghcr.io/r3ps4j/steamcmd-yolk:proton` if the egg used `parkervcp/steamcmd:proton` before) to the "Docker Images" part of an egg that is currently using one of the above images. Then select this yolk for the server with which you want to use it.
2. Go to the "Install Script" part of the egg configuration, and change the script container to `ghcr.io/r3ps4j/steamcmd-yolk:root`. *Note that this image is based on debian, if the script container was not set to debian before it might cause issues.*
