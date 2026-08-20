#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly dir
cd "${dir}/.."

# test if requirements are installed
PROGRAMS=("vendir" "kustomize" "yq" "jq")
for program in "${PROGRAMS[@]}"; do
    if ! command -v "${program}" &> /dev/null; then
        echo "${program} not installed; aborting."
        exit 1
    fi
done

set -x
# Sync using vendir
vendir sync
{ set +x; } 2>/dev/null

# patches
./sync/patches/base/patch.sh
./sync/patches/render/patch.sh
./sync/patches/controller/patch.sh
./sync/patches/images/patch.sh
./sync/patches/labels/patch.sh

# chart should always be last
./sync/patches/chart/patch.sh

if ! git diff --quiet --exit-code helm/ ; then
    echo -e "\n---------- PRINTING GIT DIFF ----------\n"
    git diff helm/
fi
