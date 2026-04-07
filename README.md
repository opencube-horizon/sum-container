# SUM Container

HPE Smart Update Manager in a Docker container, used to manage firmware in our HPE testbed hardware.

Note: the resulting container may not be redistributed!


## Build

    make

This should give you a container `sum` in your local Podman or Docker.
You can override the version of SUM by using:

    make VER=12.3.0
    
Please note: there is a delay between a new release of SUM (or actually any software) and their appearance on the HPE SDR, which this container uses to pull software.

## Usage

This container defines 2 volumes:

  - `/data` for logs, session data, etc.
  - `/assets` for the baseline images
  
It would be best to pre-create them to have them properly named:

    podman volume create sum-assets
    podman volume create sum-data
    
To start the container (substitute `podman` with `docker` if needed):

    podman run --name sum -d -p 63001:63001 -p 63002:63002 -e SUM_ROOT_PASSWORD=my-secret -v sum-assets:/assets -v sum-data:/data sum:12.2.0-0
    
The entrypoint script also supports `SUM_ROOT_PASSWORD_FILE` if you want to leverage secret files.
Example with Podman secrets:

    printf "Gr8P@ssword!" | podman secret create sum-password -
    podman run \
      --name sum \
      -d -p 63001:63001 -p 63002:63002 \
      --secret=sum-password \
      -e SUM_ROOT_PASSWORD_FILE=/run/secrets/sum-password \
      -v sum-assets:/assets -v sum-data:/data \
      sum:12.2.0-0

## Mirroring Baselines

The container includes a `mirror.sh` script to download HPE SDR baselines for offline use with SUM.
To mirror a baseline into the `/assets` volume:

    podman exec sum /mirror.sh spp-gen10/2025.09.00.00

This uses `lftp` to mirror the SDR repository into `/assets/spp-gen10/2025.09.00.00`.
Run the script without arguments to see available baselines already mirrored.

## Security

The root password for SUM's web interface can be set via two mechanisms:

  - `SUM_ROOT_PASSWORD` — plain-text environment variable (convenient for development)
  - `SUM_ROOT_PASSWORD_FILE` — path to a file containing the password (recommended for production)

If both are set, `SUM_ROOT_PASSWORD_FILE` takes precedence.
For production deployments, prefer `SUM_ROOT_PASSWORD_FILE` with container secrets to avoid exposing the password in environment variables (visible via `podman inspect`).

## HPE Appliance ISO

The `iso/` subdirectory builds a minimal bootable ISO containing HPE Agentless Management Service (amsd) and Integrated Smart Update Tools (iSUT).
Boot it via iLO Virtual Media so SUM can inventorise and update firmware/drivers through the iLO CHIF channel — no network required on the target server.

### Building the ISO

    make -C iso iso

This runs a KIWI build via `docker buildx` using the `docker-container` driver with BuildKit's `security.insecure` entitlement (no `--privileged` required).
A buildx builder named `kiwi` is created automatically on first run.
Output lands in `iso/build/result/`.

Override versions:

    make -C iso iso VER=1.1.0 SPP=2026.03.00.00

| Variable | Default        | Description                              |
|----------|----------------|------------------------------------------|
| `VER`    | `1.0.0`        | Synthetic ISO version (semver)           |
| `REV`    | `0`            | Build revision                           |
| `SPP`    | `2026.03.00.00`| HPE SPP baseline (pins package versions) |
| `AMSD_V` | `4.6.0`        | Expected amsd version (informational)    |
| `SUT_V`  | `6.6.0`        | Expected sut version (informational)     |

### Versioning

The ISO uses a synthetic semver (`VER`) decoupled from HPE package versions.
The SPP baseline date pins the actual amsd/sut versions.
A version mapping is embedded in the ISO at `/etc/hpe-iso-version` and can also be generated as `build/manifest.yaml`:

    make -C iso manifest

KIWI automatically produces a `.packages` file alongside the ISO containing the full RPM bill of materials.

### Remote builders

Point `DOCKER_HOST` at a remote Docker engine to offload the build:

    make -C iso iso DOCKER_HOST=tcp://builder.example.com:2376
