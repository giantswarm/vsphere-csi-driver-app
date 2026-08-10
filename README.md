# `vsphere-csi-driver-app`

This repository contains the chart which is used for deploying the vSphere CSI (Container Storage Interface) driver on Giant Swarm CAPV clusters.

Upstream does not publish a Helm chart. It publishes a single manifest, `manifests/vanilla/vsphere-csi-driver.yaml`.
This repository vendors that manifest and converts it into a chart.

## Updating the chart

The chart in [helm/vsphere-csi-driver](./helm/vsphere-csi-driver) is fully generated. Do not edit it by hand.

Renovate opens a pull request which changes `ref:` in [vendir.yml](./vendir.yml).
**Do not merge that pull request directly.** Check out the branch, run the sync script, then commit the result:

```bash
./sync/sync.sh
```

The script prints the `helm/` diff at the end so that you can review the change.

### Requirements

The following programs must be on your `PATH`:

- [`vendir`](https://carvel.dev/vendir/)
- [`kustomize`](https://kustomize.io/)
- [`yq`](https://github.com/mikefarah/yq)
- `jq`

### How the sync works

`sync/sync.sh` runs `vendir sync` and then applies each patch in order. Order is significant.

| Step | Directory | Purpose |
| --- | --- | --- |
| 1 | `sync/patches/base` | Deletes the chart, then seeds it with the Giant Swarm owned files. |
| 2 | `sync/patches/render` | Renders the upstream manifest into chart templates with kustomize. |
| 3 | `sync/patches/controller` | Makes the controller security context, affinity and tolerations configurable through values. |
| 4 | `sync/patches/images` | Points the images at `gsoci.azurecr.io/giantswarm` and applies our retagged image names. |
| 5 | `sync/patches/labels` | Injects the `labels.common` template into every resource. |
| 6 | `sync/patches/chart` | Writes `Chart.yaml`. Must be last. |

`sync/kustomize` holds the kustomize overlay. `vendir` writes the upstream manifest into `sync/kustomize/input`.
The overlay sets the namespace to `{{ .Release.Namespace }}` and applies the three strategic merge patches in `sync/kustomize/patches`.

`vendor` and `sync/kustomize/input` are generated. They are not committed. `vendir.lock.yml` records the upstream commit and is committed.

### Versions

`Chart.yaml` holds two versions:

- `appVersion` is the upstream version. `sync/patches/chart/patch.sh` reads it from `ref:` in `vendir.yml`.
- `version` is the Giant Swarm app version. The release process controls it. The sync script keeps the current value.

## Compatibility

Compatibility with Kubernetes versions is documented in the [upstream repository](https://github.com/kubernetes-sigs/vsphere-csi-driver?tab=readme-ov-file#vsphere-csi-driver-releases).
