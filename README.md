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

  - `/data` for for logs, session data, etc.
  - `/assets` for the baseline images
  
It would be best to pre-create them to have them properly named:

    podman volume create sum-assets
    podman volume create sum-data
    
To start the container:

    docker run --name sum -d -p 63001:63001 -p 63002:63002 -e SUM_ROOT_PASSWORD=my-secret -v sum-assets:/assets -v sum-data:/data sum:12.2.0-0
    
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
