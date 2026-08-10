#!/usr/bin/env bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
source "${SCRIPT_DIR}"/../../_helpers.sh
cd "${REPO_DIR}"

echo "Rendering the upstream manifest into chart templates"

# kustomize writes one file per resource, which gives the templates their
# '<apiVersion>_<kind>_<name>.yaml' names.
rm -rf "${KUSTOMIZE_DIR}/tmp"
mkdir -p "${KUSTOMIZE_DIR}/tmp"

set -x
kustomize build "${KUSTOMIZE_DIR}" -o "${KUSTOMIZE_DIR}/tmp/"
{ set +x; } 2>/dev/null

find "${KUSTOMIZE_DIR}/tmp/" -name '*.yaml' -exec cp -pr '{}' "${CHART_DIR}/templates/" ';'

rm -rf "${KUSTOMIZE_DIR}/tmp"

# We do not support Windows nodes.
rm -f "${CHART_DIR}/templates/apps_v1_daemonset_vsphere-csi-node-windows.yaml"
