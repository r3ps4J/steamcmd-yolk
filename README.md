# steamcmd-yolk

A pterodactyl yolk for hosting steamcmd servers on amd64 and arm64 based on [palworld-server-docker](https://github.com/thijsvanloef/palworld-server-docker/) by [thijsvanloef](https://github.com/thijsvanloef) and the [steamcmd yolk](https://github.com/parkervcp/yolks/blob/master/steamcmd/) by [parkervcp](https://github.com/parkervcp).

## arm64

Arm64 compatibility is done through box86 and box64 thanks to the [steamcmd-arm64 image](https://github.com/sonroyaalmerol/steamcmd-arm64) by [sonroyaalmerol](https://github.com/sonroyaalmerol). This is a drop-in replacement for [cm2network/steamcmd](https://github.com/CM2Walki/steamcmd/), which is used for amd64.

## Usage

You can use this yolk like any other yolk. Note that steamcmd is already installed in /home/steam/steamcmd. You can use the `STEAMCMDDIR` environment variable to get the right path.

Use `${STEAMCMDDIR}/steamcmd.sh` to use steamcmd, for example:

```bash
${STEAMCMDDIR}/steamcmd.sh +force_install_dir /mnt/server +login anonymous +app_update ${SRCDS_APPID} validate +exit
```

This image doesn't work well by just running it without an installation script. I don't know why, but just install the game through an installation script if you make an egg based on this. Running this image outside of pterodactyl does not require an installation script.

## Drop-in replacement

This yolk can be used as a drop-in replacement for parkervcp's `games:source` and `steamcmd` yolks. In order to use it you will have to do 2 things.

1. Add `ghcr.io/r3ps4j/steamcmd-yolk` to the "Docker Images" part of an egg that is currently using one of the above images. Then select this yolk for the server with which you want to use it.
2. Go to the "Install Script" part of the egg configuration, and change the script container to `ghcr.io/r3ps4j/steamcmd-yolk`. *Note that this image is based on debian, if the script container was not set to debian before it might cause issues.*
