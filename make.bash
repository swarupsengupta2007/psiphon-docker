#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

function help_message() {
	echo "Usage: $0 [OPTIONS]"
	echo "Options:"
	echo "  --targets, -t <targets>      Comma-separated list of target platforms (default: current, use 'all' for all supported targets)"
	echo "  --version, -v <version>      Psiphon version to build (default: latest available)"
	echo "  --go, -g <version>           Go version to use (default: 1.22.7)"
	echo "  --load                       Load the built image into local Docker (cannot be used with --push)"
	echo "  --push                       Push the built image to Docker Hub (cannot be used with --load)"
	echo "  --supported-targets          Show supported targets and exit"
	echo "  --current-target             Show current target platform and exit"
	echo "  --help, -h                   Show this help message and exit"
	exit ${1:-1}
}

EXTRA_BUILD_ARGS=""
VERSION=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--help|-h)
			help_message 0
			;;
		--targets=*)
			TARGETS="${1#*=}"
			shift
			;;
		-t | --targets)
			TARGETS="$2"
			shift 2
			;;
		--version=*)
			VERSION="${1#*=}"
			shift
			;;
		-v | --version)
			VERSION="$2"
			shift 2
			;;
		--go=*)
			GO_VERSION="${1#*=}"
			shift
			;;
		-g | --go)
			GO_VERSION="$2"
			shift 2
			;;
		--supported-targets)
			echo "Supported targets: $(get_supported_targets)"
			exit 0
			;;
		--current-target)
			echo "Current target: $(get_current_target)"
			exit 0
			;;
		-l | --load)
			if [[ -n ${EXTRA_BUILD_ARGS} && ${EXTRA_BUILD_ARGS} == *"--push"* ]]; then
				echo "Error: --load and --push cannot be used together." >&2
				exit 1
			fi
			EXTRA_BUILD_ARGS="--load"
			shift
			;;
		-p | --push)
			if [[ -n ${EXTRA_BUILD_ARGS} && ${EXTRA_BUILD_ARGS} == *"--load"* ]]; then
				echo "Error: --load and --push cannot be used together." >&2
				exit 1
			fi
			EXTRA_BUILD_ARGS="--push"
			shift
			;;
		*)
			echo "Error: Unknown option '$1'" >&2
			help_message
			;;
	esac
done

TARGETS=${TARGETS:-"current"}
GO_VERSION=${GO_VERSION:-1.22.7}

MYPATH=$(dirname "$(readlink -f "$0")")
source "${MYPATH}/latest_version.sh"

DOCKER_BUILD_ARGS=()

if [[ -n "${TARGETS}" ]]; then
	DOCKER_BUILD_ARGS+=(--build-arg TARGETS=${TARGETS})
fi
if [[ -z "${VERSION}" ]]; then
	VERSION=$(get_latest_version)
fi
if [[ -n "${VERSION}" ]]; then
	VERSION=$(normalize_version "${VERSION}")
	DOCKER_BUILD_ARGS+=(--build-arg PSIPHON_VERSION=${VERSION})
fi
if [[ -n "${GO_VERSION}" ]]; then
	DOCKER_BUILD_ARGS+=(--build-arg GO_VERSION=${GO_VERSION})
fi

DECIPHERED_TARGETS=$(decipher_targets "${TARGETS}")

docker buildx build \
				"${DOCKER_BUILD_ARGS[@]}" \
				-t swarupsengupta2007/psiphon:"${VERSION#v}" \
				-t swarupsengupta2007/psiphon:latest \
				--platform "${DECIPHERED_TARGETS}" . \
				${EXTRA_BUILD_ARGS}
