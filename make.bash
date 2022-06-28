#!/bin/bash

TARGETS="linux/amd64,linux/386,linux/arm64,linux/arm/v7,linux/arm/v6"

sudo docker buildx build --build-arg TARGETS=${TARGETS} -t swarupsengupta2007/psiphon:2.0.23 \
-t swarupsengupta2007/psiphon:latest --platform ${TARGETS} . $1
