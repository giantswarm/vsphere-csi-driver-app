#!/bin/bash

set -eo pipefail
set -x

if [[ -z "${GITHUB_ACTIONS}" ]]; then
# Not running in a GH action

chart_file="helm/vsphere-csi-app/Chart.yaml"

current_version=$(yq e '.version' $chart_file)

update_version() {
    new_version=$1
    yq e -i ".version = \"$new_version\" | .appVersion = \"$new_version\"" "$chart_file"
    echo "Chart version updated: $current_version -> $new_version"
}

read -p "Do you want to update the chart's version? [n] No, [m] Minor, [p] Patch: " choice

case $choice in
"n")
    echo "No version update."
    ;;
"m")
    new_version=$(echo $current_version | awk -F. '{$2++; printf "%d.%d.%d",$1,$2,$3}')
    update_version "$new_version"
    ;;
"p")
    new_version=$(echo $current_version | awk -F. '{$3++; printf "%d.%d.%d",$1,$2,$3}')
    update_version "$new_version"
    ;;
*)
    echo "Invalid choice. Please enter n, m, or p."
    ;;
esac

echo "\n*********************************\n🔔 Please update the CHANGELOG 🔔\n*********************************"

else
echo "Running in GH Action - skipping interactive task"
fi