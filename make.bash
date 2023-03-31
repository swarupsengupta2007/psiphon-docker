#!/bin/bash

TARGETS="linux/amd64,linux/386,linux/arm64,linux/arm/v7,linux/arm/v6"
VERSION=2.0.29

sudo docker buildx build --build-arg TARGETS=${TARGETS} --build-arg VERSION=${VERSION} -t swarupsengupta2007/psiphon:${VERSION} \
-t swarupsengupta2007/psiphon:latest --platform ${TARGETS} . $1
