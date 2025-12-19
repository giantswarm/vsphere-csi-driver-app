#!/bin/bash
set -x
set -euo pipefail

base_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
chart_dir="./helm/vsphere-csi-driver"
KUSTOMIZE="${1:-kustomize}"

cd "$base_dir"

# The goal here is to control versions only from Chart.yaml overrides with Renovate and grab that version here.
VERSION=$(yq e '.version' "config/vsphere-csi-driver/overwrites/Chart.yaml")

"./hack/clone-git-repo.sh" \
  "kubernetes-sigs/vsphere-csi-driver" \
  "v$VERSION" \
  "vsphere-csi-driver"

rm -Rf "$chart_dir"

cp -R \
  "./config/vsphere-csi-driver/overwrites/." \
  "$chart_dir/"

cp -R \
  "./tmp/vsphere-csi-driver/manifests/vanilla/vsphere-csi-driver.yaml" \
  "./config/vsphere-csi-driver/input/"

# Customizations

mkdir -p "./config/vsphere-csi-driver/tmp/"
${KUSTOMIZE} build "./config/vsphere-csi-driver" -o "./config/vsphere-csi-driver/tmp/"

find \
  "./config/vsphere-csi-driver/tmp/" \
  -name '*.yaml' -exec \
  cp -prv '{}' \
  "$chart_dir/templates/" ';'

rm -Rf "$chart_dir/templates/apps_v1_daemonset_vsphere-csi-node-windows.yaml"