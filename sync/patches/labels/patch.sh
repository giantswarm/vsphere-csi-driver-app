#!/usr/bin/env bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
source "${SCRIPT_DIR}"/../../_helpers.sh
cd "${REPO_DIR}"

for file in "${CHART_DIR}"/templates/*yaml
do
  echo "Injecting common labels to $file"
  if grep -q "labels.common" < "$file"; then
        echo "Common labels already exist.Skipping"
        continue
  fi

  # inject common labels to resources that have already labels section
  injected='{{- include "labels.common" $ | nindent 4 }}'
  sed -i -z "s/\n\s\slabels:/\n  labels:\n    $injected/g" "$file"

  # inject common labels to list resources that have already labels section
  if grep -q "kind: List" < "$file"; then
    injected='{{- include "labels.common" $ | nindent 6 }}'
    sed -i -z "s/\n\s\s\s\slabels:/\n    labels:\n      $injected/g" "$file"
  fi

  if ! grep -q "^  labels:" < "$file"; then
    # labels section doesn't exist. adding it.
    injected='{{- include "labels.common" $ | nindent 4 }}'
    sed -i -z "s/\nmetadata:\n/\nmetadata:\n  labels:\n    $injected\n/g" "$file"
  fi

  if ! grep -q "labels.common" < "$file"; then
    echo "Couldn't inject common labels. Please check. Exiting."
    exit 1
  fi
done
