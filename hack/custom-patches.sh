#!/bin/bash
set -x
set -o errexit
set -o nounset
set -o pipefail

YQ="./bin/yq"

csi_controller_manifest="helm/vsphere-csi-driver/templates/apps_v1_deployment_vsphere-csi-controller.yaml"
csi_nodeplugin_manifest="helm/vsphere-csi-driver/templates/apps_v1_daemonset_vsphere-csi-node.yaml"

# Add SecurityContext to the containers.
${YQ} eval '.spec.template.spec.securityContext.remove-this-key="'"
{{- with .Values.podSecurityContext }}
  {{- . | toYaml | nindent 8 }}
{{- end }}
"'" | .spec.template.spec.containers[].securityContext.remove-this-key="'"
{{- with .Values.containerSecurityContext }}
  {{- . | toYaml | nindent 12 }}
{{- end }}
"'"' ${csi_controller_manifest} > ${csi_controller_manifest}.tmp

# Remove existing runAsNonRoot keys added upstream since we set it in the chart's values.
# https://github.com/giantswarm/cloud-provider-vsphere-app/blob/6556f98de46ff45b3a8ce9080752ca1050bbee0b/helm/cloud-provider-vsphere/charts/vsphere-csi-driver/values.yaml#L59
cat ${csi_controller_manifest}.tmp \
  | grep -v 'remove-this-key' \
  | grep -v 'runAsNonRoot' \
  | grep -v 'runAsUser: 65532' \
  | grep -v 'runAsGroup: 65532' \
  > ${csi_controller_manifest}

rm -rf ${csi_controller_manifest}.tmp

# Replace image registries with our own in the manifests.
echo "Replacing image registries with Giant Swarm's"

"./hack/replace-image-registries.sh" "$csi_controller_manifest" "syncer" "csi-vsphere-syncer"
"./hack/replace-image-registries.sh" "$csi_controller_manifest" "driver" "csi-vsphere-driver"
"./hack/replace-image-registries.sh" "$csi_nodeplugin_manifest" "driver" "csi-vsphere-driver"
