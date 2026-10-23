#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd ) ; readonly SCRIPT_DIR
source "${SCRIPT_DIR}"/_helpers.sh

# this script is deliberately not called by sync.sh; the sync diff check runs
# sync.sh on every pull request and it must not rewrite the changelog.

CHANGELOG="${REPO_DIR}/CHANGELOG.md" ; readonly CHANGELOG

# get the upstream sync version from vendir.yml
UPSTREAM_SYNC_VERSION=$(yq -r .directories[0].contents[0].git.ref "${REPO_DIR}"/vendir.yml) ; readonly UPSTREAM_SYNC_VERSION

readonly ENTRY_PREFIX="- Update upstream vsphere-csi-driver chart to "
ENTRY="${ENTRY_PREFIX}${UPSTREAM_SYNC_VERSION}." ; readonly ENTRY

echo "Adding changelog entry: ${ENTRY}"

TMP_FILE=$(mktemp) ; readonly TMP_FILE

# add the entry to the top of the Unreleased section. running this twice with the
# same version must not change the file, otherwise the sync workflow loops.
awk -v entry="${ENTRY}" -v prefix="${ENTRY_PREFIX}" '
# print a line, but never two blank lines in a row
function out(line) {
    if (line == "") {
        if (prev_blank) { return }
        prev_blank = 1
    } else {
        prev_blank = 0
    }
    print line
}
# print the Unreleased section: one Changed section with the entry first, then
# the other sections in their original order
function flush(    i) {
    out("### Changed") ; out("") ; out(entry)
    for (i = 1; i <= n_changed; i++) { out(changed[i]) }
    if (n_other) { out("") }
    for (i = 1; i <= n_other; i++) { out(other[i]) }
}
$0 == "## [Unreleased]" {
    out($0) ; out("")
    in_unreleased = 1
    section = "### Changed"
    next
}
# the next release heading ends the Unreleased section
in_unreleased && /^## \[/ { flush() ; out("") ; in_unreleased = 0 }
# collect the Unreleased section. merge all Changed sections into one list, and
# drop the entry from any previous run.
in_unreleased {
    if (/^### /) {
        section = $0
        if (section != "### Changed") { other[++n_other] = $0 }
    } else if (section != "### Changed") {
        other[++n_other] = $0
    } else if ($0 != "" && index($0, prefix) != 1) {
        changed[++n_changed] = $0
    }
    next
}
{ out($0) }
END { if (in_unreleased) { flush() } }
' "${CHANGELOG}" > "${TMP_FILE}"

# keep the mode of the existing file
cat "${TMP_FILE}" > "${CHANGELOG}"
rm "${TMP_FILE}"
