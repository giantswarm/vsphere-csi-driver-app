#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# root dir of the git repository
REPO_DIR=$(git rev-parse --show-toplevel) ; readonly REPO_DIR

# path of the calling patch script, relative to the repository root
SCRIPT_DIR_REL=".${SCRIPT_DIR#"${REPO_DIR}"}" ; readonly SCRIPT_DIR_REL

# root dir of the generated helm chart
CHART_DIR="${REPO_DIR}/helm/vsphere-csi-driver" ; readonly CHART_DIR

# root dir of the vendir synced upstream repository
VENDIR_SYNC_DIR="${REPO_DIR}/vendor/vsphere-csi-driver" ; readonly VENDIR_SYNC_DIR

# root dir of the kustomize overlay which renders the upstream manifest
KUSTOMIZE_DIR="${REPO_DIR}/sync/kustomize" ; readonly KUSTOMIZE_DIR
