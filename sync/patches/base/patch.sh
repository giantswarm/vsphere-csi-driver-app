#!/usr/bin/env bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
source "${SCRIPT_DIR}"/../../_helpers.sh
cd "${REPO_DIR}"

echo "Seeding the chart with the Giant Swarm owned files"

# The chart is fully generated, so start from a clean directory every time.
rm -rf "${CHART_DIR}"
mkdir -p "${CHART_DIR}"

# Copy with a trailing '/.' so that dotfiles such as .kube-linter.yaml are included.
set -x
cp -R "${SCRIPT_DIR}"/manifests/. "${CHART_DIR}"/
{ set +x; } 2>/dev/null
