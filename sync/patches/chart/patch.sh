#!/usr/bin/env bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
source "${SCRIPT_DIR}"/../../_helpers.sh
cd "${REPO_DIR}"

echo "Updating Chart.yaml"

# We need to get the current version of the chart in order to reset it after
# copying Chart.yaml over. We retrieve this from the GitHub API because the
# local chart has now been regenerated.
CURRENT_CHART_VERSION=$(curl -s https://api.github.com/repos/giantswarm/vsphere-csi-driver-app/releases/latest | jq -r .name)
# remove leading 'v' if present
CURRENT_CHART_VERSION="${CURRENT_CHART_VERSION#v}"

# The appVersion field tracks the upstream version we sync against, so read it
# from vendir.yml.
UPSTREAM_SYNC_VERSION=$(yq -r '.directories[0].contents[0].git.ref' "${REPO_DIR}/vendir.yml")
# strip leading 'v' if present
UPSTREAM_SYNC_VERSION="${UPSTREAM_SYNC_VERSION#v}"

set -x
cp "${SCRIPT_DIR}"/manifests/Chart.yaml "${CHART_DIR}"/Chart.yaml
{ set +x; } 2>/dev/null

# set the app version in Chart.yaml
sed -i -E "s/APP_VERSION_PLACEHOLDER/${UPSTREAM_SYNC_VERSION}/g" "${CHART_DIR}/Chart.yaml"

# reset the version in Chart.yaml
sed -i -E "s/CHART_VERSION_PLACEHOLDER/${CURRENT_CHART_VERSION}/g" "${CHART_DIR}/Chart.yaml"
