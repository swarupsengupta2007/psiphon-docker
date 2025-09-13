
# Psiphon Docker
Docker image for Psiphon

Psiphon is an Internet censorship circumvention system. <br>
This Docker image runs the ConsoleClient from the [psiphon-tunnel-core](https://github.com/Psiphon-Labs/psiphon-tunnel-core "psiphon-tunnel-core").

> This build uses the `docker buildx` plugin with the `docker-container` driver. <br>
> Docker image available at [swarupsengupta2007/psiphon](https://hub.docker.com/r/swarupsengupta2007/psiphon "swarupsengupta2007/psiphon"). <br>

```bash
# Clone this repo
git clone https://github.com/swarupsengupta2007/psiphon-docker
```

# Building<br>

1. Ensure buildx is enabled for Docker
2. Create a builder instance for multi-arch
3. Build Docker image for current platform or multi-arch
```bash
# choose target platforms
TARGETS="linux/amd64,linux/386,linux/arm64,linux/arm/v7,linux/arm/v6"

# Create a builder instance if it doesn't exist
docker buildx create --name cross-platform --platform ${TARGETS} --use 

# Build for the current platform and load to Docker image
docker buildx build -t <your_tag> . --load

# If not already done, install the required cross-platform emulators
docker run --privileged --rm tonistiigi/binfmt --install all

# run the script, this will build the image for the current platform and load it to Docker
./make.bash --load
```

Build-args available
|build-arg|Description|Default|
|--|--|--|
|VERSION|psiphon-tunnel-core release version|latest|
|TARGETS|\<BUIDLOS\>/\<BUILDARCH\> (Targets for cross-compilation for the build stage)|current platform|
|GO_VERSION|Go version to use for building the psiphon-tunnel-core binary|1.22.7|
---

# Usage

## Using docker-compose (recommended) <br>
```yaml
version: "3.5"
services:
  psiphon:
    image: swarupsengupta2007/psiphon:latest
    container_name: psiphon
    environment:
      - PUID=1000
      - PGID=1000
      - HTTP_PORT=8080
      - SOCKS_PORT=1080
      - DEVICE_REGION=IN
      - EGRESS_REGION=SG
    volumes:
      - /path/to/psiphon/config:/config
    ports:
      - 1080:1080
      - 8080:8080
    restart: unless-stopped
```

## Using docker-cli <br>
```bash
docker run -d                                  \
    --name psiphon                             \
    --restart=unless-stopped                   \
    -p 8080:8080                               \
    -p 1080:1080                               \
    -e HTTP_PORT=8080                          \
    -e SOCKS_PORT=1080                         \
    -e DEVICE_REGION=IN                        \
    -e EGRESS_REGION=SG                        \
    -v /home/swarup/psiphon/config/:/config    \
    swarupsengupta2007/psiphon
```

The following Environment var are available (only applicable when running for the first time with no psiphon.config in the mounted config directory)<br>
|ENV variable|Description|Default|
|--|--|--|
|PUID|The UID for psiphon process|1000|
|PGID|The GID for psiphon process|1000|
|HTTP_PORT|The HTTP proxy port|8080|
|SOCKS_PORT|The SOCKS proxy port|1080|
|DEVICE_REGION|The device region for Psiphon client|IN|
|EGRESS_REGION|The egress region for Psiphon client|SG|

# Configuration
The Psiphon client configuration is stored in the mounted config directory. /config must be mounted and writable by the psiphon process. <br>

# Healthcheck
The container has a healthcheck script that checks if the Psiphon client is running and healthy. <br>
You can check the health status of the container using the following command:
```bash
docker inspect --format='{{json .State.Health}}' psiphon
```
