#!/usr/bin/env bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
source "${SCRIPT_DIR}"/../../_helpers.sh
cd "${REPO_DIR}"

echo "Replacing image registries with Giant Swarm's"

readonly REGISTRY='gsoci.azurecr.io'
readonly REPOSITORY='giantswarm'

csi_controller_manifest="${CHART_DIR}/templates/apps_v1_deployment_vsphere-csi-controller.yaml"
csi_nodeplugin_manifest="${CHART_DIR}/templates/apps_v1_daemonset_vsphere-csi-node.yaml"

# Point every image at our own registry and repository, then rename the
# upstream image to the name we retag it under.
# e.g. https://github.com/giantswarm/retagger/blob/4fa7dff7f68ff5141267c4e788cea6ded1de6277/images/customized-images.yaml#L97-L99
replace_image_registry() {
  local filepath="${1}"
  local upstream_image="${2}"
  local gs_image="${3}"

  # Replace the registry section to our own.
  sed -i "s|\(image:\s*\)[^/]\+/|\1$REGISTRY/|" "$filepath"

  # Replace the repository section to our own, including subpaths.
  sed -i "s|\(image:\s*[^/]\+\)/.*/|\1/$REPOSITORY/|" "$filepath"

  # Replace upstream image names with our retagged names.
  sed -i "/image:/ s|$REGISTRY/$REPOSITORY/$upstream_image|$REGISTRY/$REPOSITORY/$gs_image|g" "$filepath"
}

replace_image_registry "$csi_controller_manifest" "syncer" "csi-vsphere-syncer"
replace_image_registry "$csi_controller_manifest" "driver" "csi-vsphere-driver"
replace_image_registry "$csi_nodeplugin_manifest" "driver" "csi-vsphere-driver"
