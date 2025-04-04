
# Psiphon Docker
Docker image for Psiphon

Psiphon is an Internet censorship circumvention system. <br>
This docker image runs the ConsoleClient from the [psiphon-tunnel-core](https://github.com/Psiphon-Labs/psiphon-tunnel-core "psiphon-tunnel-core").

> This build uses `docker buildx` plugin with `docker-container` driver. <br>
> Docker image available at [swarupsengupta2007/psiphon](https://hub.docker.com/r/swarupsengupta2007/psiphon "swarupsengupta2007/psiphon"). <br>
> This is built on base image from [swarupsengupta2007/apine-s6-docker](https://github.com/swarupsengupta2007/alpine-s6-docker "swarupsengupta2007/apine-s6-docker")

```bash
# Clone this repo
git clone https://github.com/swarupsengupta2007/psiphon-docker
```

# Building<br>

1. Ensure buildx is enabled for docker
2. Create a builder instance for multi-arch
3. Build docker image for current platform or multi-arch
```bash
# choose target platforms
TARGETS="linux/amd64,linux/386,linux/arm64,linux/arm/v7,linux/arm/v6"

# Create a builder instance if it doesn't exist
docker buildx create --name cross-platform --platform ${TARGETS} --use 

# Build for current platform and load to docker image
docker buildx build -t <your_tag> . --load

# If not already done, install the required cross-platform emulators
docker run --privileged --rm tonistiigi/binfmt --install all

# build for multi-arch and push to registry
# optional, choose targets (defaults to the following list)
export TARGETS="linux/amd64,linux/386,linux/arm64,linux/arm/v7,linux/arm/v6"

# choose psiphon version (currently 2.0.32)
export PSIPHON_VERSION=2.0.32

# choose go version (currently 1.23.7)
export GO_VERSION=1.23.7

# run the script
./make.bash --push
```

Build-args available
|build-arg|Description|
|--|--|
|VERSION|psiphon-tunnel-core release version|
|TARGETS|\<BUIDLOS\>/\<BUILDARCH\> (Targets for cross-compilation for the build stage)|
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
    -v /home/swarup/psiphon/config/:/config    \
    swarupsengupta2007/psiphon
```

The following Environment var are available<br>
|ENV variable|Description|Default|
|--|--|--|
|PUID|The UID for psiphon process|1000|
|PGID|The GID for psiphon process|1000|

Following ports and volumes are available 
|Option|switch|Description|Default|
|--|--|--|--|
|HTTP PORT|-p <host_port>:8080|http proxy port|8080|
|SOCKS PORT|-p <host_port>:1080|socks proxy port|1080|
|VOLUME|-v /path/to/config:/config|The container storage|/config|
