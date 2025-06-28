#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# This file can only be sourced, not executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "This script is intended to be sourced, not executed directly." >&2
    exit 1
fi

function validate_version_format() {
    local v="$1"
    [[ "${v}" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

function get_latest_version() {
    local json version
    json="$(curl -fsSL https://api.github.com/repos/Psiphon-Labs/psiphon-tunnel-core/releases/latest)"
    if command -v jq >/dev/null 2>&1; then
        version="$(printf '%s' "${json}" | jq -r .tag_name)"
    else
        version="$(printf '%s' "${json}" \
            | grep -m1 '"tag_name":' \
            | sed -E 's/.*"tag_name": ?"([^"]+)".*/\1/')"
    fi

    if ! validate_version_format "${version}"; then
        echo "I tried to get the latest version of Psiphon without jq but it didn't work." >&2 
        echo "Please install jq or specify the version manually." >&2
        exit 1
    fi

    printf '%s\n' "${version}"
}

function normalize_version() {
    local v="$1"
    if [[ "${v}" =~ ^v ]]; then
        echo "${v}"
    else
        echo "v${v}"
    fi
}

function get_supported_targets() {
    echo "linux/amd64,linux/386,linux/arm64,linux/arm/v7,linux/arm/v6"
}

function get_current_target() {
    echo "$(go env GOOS)/$(go env GOARCH)"
}

function decipher_targets() {
    local targets="$1"
    if [[ "${targets}" == "current" ]]; then
        echo "$(get_current_target)"
    elif [[ "${targets}" == "all" ]]; then
        echo "$(get_supported_targets)"
    else
        echo "${targets}"
    fi
}