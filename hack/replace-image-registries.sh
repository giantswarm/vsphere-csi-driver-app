#!/bin/bash
set -euo pipefail
set -x

# This script replaces any image registry/repository to our own.
# It also replaces the default image names with our retagged names.

FILEPATH="${1}"
UPSTREAM_IMAGE="${2}"
GS_IMAGE="${3}"

REGISTRY='gsoci.azurecr.io'
REPOSITORY='giantswarm'

# Replace the registry section to our own.
sed -i "s|\(image:\s*\)[^/]\+/|\1$REGISTRY/|" $FILEPATH

# Replace the repository section to our own, including subpaths.
sed -i "s|\(image:\s*[^/]\+\)/.*/|\1/$REPOSITORY/|" $FILEPATH

# Replace upstream image names with our retagged names.
# e.g. https://github.com/giantswarm/retagger/blob/4fa7dff7f68ff5141267c4e788cea6ded1de6277/images/customized-images.yaml#L97-L99

sed -i "/image:/ s|$REGISTRY/$REPOSITORY/$UPSTREAM_IMAGE|$REGISTRY/$REPOSITORY/$GS_IMAGE|g" $FILEPATH