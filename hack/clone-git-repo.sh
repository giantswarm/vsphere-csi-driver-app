#!/bin/bash

set -euo pipefail
set -x

base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

REPO="${1}"
BRANCH_OR_TAG="${2}"
CLONE_FOLDER="${3}"

if [ ! -d "$base_dir/tmp" ]; then
  mkdir "$base_dir/tmp"
fi

cd "$base_dir/tmp"
rm -Rf "$CLONE_FOLDER"

git clone --depth=1 --branch "${BRANCH_OR_TAG}" "https://github.com/${REPO}.git" "$CLONE_FOLDER"