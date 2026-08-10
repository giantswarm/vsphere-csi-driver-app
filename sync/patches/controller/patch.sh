#!/usr/bin/env bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
source "${SCRIPT_DIR}"/../../_helpers.sh
cd "${REPO_DIR}"

echo "Applying custom patches to the controller deployment"

csi_controller_manifest="${CHART_DIR}/templates/apps_v1_deployment_vsphere-csi-controller.yaml"

# Remove existing affinity and tolerations added upstream since we want to control them via Helm values.
yq -i 'del(.spec.template.spec.affinity)' "${csi_controller_manifest}"
yq -i 'del(.spec.template.spec.tolerations)' "${csi_controller_manifest}"

# Add SecurityContext to the containers.
# Add interface to configure affinity and tolerations for the controller deployment.
#
# yq cannot write a bare Helm block, so each block is written as the value of a
# 'remove-this-key' key. yq emits it as a block scalar, and the grep below then
# drops the key line and leaves the Helm block behind.
#
# The blocks must not start with a newline. A leading newline becomes an empty
# first line of the block scalar, which survives the grep.
export POD_SECURITY_CONTEXT='{{- with .Values.podSecurityContext }}
  {{- . | toYaml | nindent 8 }}
{{- end }}
'
export CONTAINER_SECURITY_CONTEXT='{{- with .Values.containerSecurityContext }}
  {{- . | toYaml | nindent 12 }}
{{- end }}
'
export CONTROLLER_AFFINITY='{{- with .Values.controller.affinity }}
  {{- . | toYaml | nindent 8 }}
{{- end }}
'
export CONTROLLER_TOLERATIONS='{{- with .Values.controller.tolerations }}
  {{- . | toYaml | nindent 8 }}
{{- end }}
'

yq eval '
  .spec.template.spec.securityContext.remove-this-key = strenv(POD_SECURITY_CONTEXT) |
  .spec.template.spec.containers[].securityContext.remove-this-key = strenv(CONTAINER_SECURITY_CONTEXT) |
  .spec.template.spec.affinity.remove-this-key = strenv(CONTROLLER_AFFINITY) |
  .spec.template.spec.tolerations.remove-this-key = strenv(CONTROLLER_TOLERATIONS)
  ' "${csi_controller_manifest}" > "${csi_controller_manifest}.tmp"

# Remove existing runAsNonRoot keys added upstream since we set it in the chart's values.
# https://github.com/giantswarm/cloud-provider-vsphere-app/blob/6556f98de46ff45b3a8ce9080752ca1050bbee0b/helm/cloud-provider-vsphere/charts/vsphere-csi-driver/values.yaml#L59
grep -v 'remove-this-key' "${csi_controller_manifest}.tmp" \
  | grep -v 'runAsNonRoot' \
  | grep -v 'runAsUser: 65532' \
  | grep -v 'runAsGroup: 65532' \
  > "${csi_controller_manifest}"

rm -f "${csi_controller_manifest}.tmp"
