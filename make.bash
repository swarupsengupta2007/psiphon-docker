#!/bin/bash

MK_TARGETS=${TARGETS:-"linux/amd64,linux/386,linux/arm64,linux/arm/v7,linux/arm/v6"}
MK_VERSION=${VERSION:-2.0.30}
MK_GO_VERSION=${GO_VERSION:-1.20}

sudo docker buildx build \
				--build-arg TARGETS=${MK_TARGETS} \
				--build-arg VERSION=${MK_VERSION} \
				--build-arg GO_VERSION=${MK_GO_VERSION} \
				-t swarupsengupta2007/psiphon:${MK_VERSION} \
				-t swarupsengupta2007/psiphon:latest \
				--platform ${MK_TARGETS} . $1
