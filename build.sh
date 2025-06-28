#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

GO=${GO:-go}
PSIPHON_VERSION=""
TARGETS=""

function help_message() {
	echo "Usage: $0 [OPTIONS] <psiphon_version>"
	echo "Options:"
	echo "  --targets <targets>    Comma-separated list of target platforms (default: current platform)"
	echo "  --version <version>    Psiphon version to build (default: latest)"
	exit ${1:-1}
}

while [[ $# -gt 0 ]]; do
	case $1 in
		--help|-h)
			help_message 0
			;;
		--targets=*)
			TARGETS="${1#*=}"
			shift
			;;
		-t | --targets)
			TARGETS="${2}"
			shift 2
			;;
		--version=*)
			PSIPHON_VERSION="${1#*=}"
			shift
			;;
		-v | --version)
			PSIPHON_VERSION="${2}"
			shift 2
			;;
		*)
			echo "Unknown option: $1"
			help_message
			;;
	esac
done

source ./lastest_version.sh

if [[ -z "${PSIPHON_VERSION}" ]]; then
	PSIPHON_VERSION=$(get_latest_version)
else
	if ! validate_version_format "$PSIPHON_VERSION"; then
		echo "Invalid Psiphon version format. Please use 'X.Y.Z' or 'vX.Y.Z' format."
		exit 1
	fi
fi

PSIPHON_VERSION=$(normalize_version "$PSIPHON_VERSION")
ALL_TARGETS="linux/amd64,linux/386,linux/arm64,linux/arm/v7,linux/arm/v6,windows/amd64,windows/386,darwin/amd64,darwin/arm64"
CURRENT_TARGET="$(go env GOOS)/$(go env GOARCH)"
TARGETS=${TARGETS:-"current"}

if [[ "${TARGETS}" == "current" ]]; then
	TARGETS="${CURRENT_TARGET}"
elif [[ "${TARGETS}" == "all" ]]; then
	TARGETS="${ALL_TARGETS}"
fi

TARGETS=${TARGETS//,/ }

BUILD_DIR=$(pwd)/tmp_build_$$
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
trap 'rm -rf "${BUILD_DIR}"' EXIT

BIN_DIR="$(pwd)/dist"
rm -rf "${BIN_DIR}"
mkdir -p "${BIN_DIR}"

curl -sL https://github.com/Psiphon-Labs/psiphon-tunnel-core/archive/refs/tags/${PSIPHON_VERSION}.tar.gz | tar xz --strip-components=1 -C "${BUILD_DIR}"
pushd "${BUILD_DIR}/ConsoleClient" > /dev/null

for PLATFORM in ${TARGETS}
do
	IFS='/' read -r OS ARCH VARIANT <<< "${PLATFORM}"
	GOEXT=""
	if [[ "${OS}" == "windows" ]]; then
		GOEXT=".exe"
	fi

	GOARM_ENV=""
	if [[ -n "${VARIANT}" ]]; then
		GOARM_ENV="GOARM=${VARIANT#v}"
	fi
	
	CGO_ENABLED=0 GOOS=${OS} GOARCH=${ARCH} ${GOARM_ENV} ${GO} build -a -tags netgo -ldflags "-s -w -extldflags '-static'" -o "${BIN_DIR}/psiphon_${PLATFORM//\//_}${GOEXT}"
done

popd > /dev/null
