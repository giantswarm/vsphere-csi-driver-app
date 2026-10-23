#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# tests for changelog.sh. each case runs the script twice in a throwaway git
# repository and compares the changelog with the expected result.
# usage: test_changelog.sh [path to changelog.sh]

SCRIPT=$(realpath "${1:-$(dirname "${BASH_SOURCE[0]}")/changelog.sh}")
WORK=$(mktemp -d)
trap 'rm -rf "${WORK}"' EXIT
FAILS=0

# run the script in a throwaway git repo. $1 = input changelog, $2 = expected
run_case() {
    local name=$1 input=$2 expected=$3 repo="${WORK}/${1}"
    mkdir -p "${repo}/sync"
    git -C "${repo}" init -q
    cp "${SCRIPT}" "${repo}/sync/changelog.sh"
    cp "$(dirname "${SCRIPT}")/_helpers.sh" "${repo}/sync/_helpers.sh"
    printf '%s\n' "${HELPERS_EXTRA}" >> "${repo}/sync/_helpers.sh"
    printf '%s\n' "${VENDIR}" > "${repo}/vendir.yml"
    printf '%s\n' "${input}" > "${repo}/CHANGELOG.md"

    (cd "${repo}" && ./sync/changelog.sh > /dev/null)
    if ! diff -u <(printf '%s\n' "${expected}") "${repo}/CHANGELOG.md" > "${WORK}/${name}.diff"; then
        echo "FAIL: ${name} (first run)" ; cat "${WORK}/${name}.diff" ; FAILS=$((FAILS + 1)) ; return
    fi
    (cd "${repo}" && ./sync/changelog.sh > /dev/null)
    if ! diff -u <(printf '%s\n' "${expected}") "${repo}/CHANGELOG.md" > "${WORK}/${name}.diff"; then
        echo "FAIL: ${name} (second run)" ; cat "${WORK}/${name}.diff" ; FAILS=$((FAILS + 1)) ; return
    fi
    echo "PASS: ${name}"
}

E="- Update upstream example-chart chart to v3.8.0."

# the path differs from the upstream repo name on purpose
GIT_VENDIR="directories:
- path: vendor
  contents:
  - path: example-chart
    git:
      url: https://github.com/example-org/other-name
      ref: v3.8.0"
RELEASE_VENDIR="directories:
- path: vendor
  contents:
  - path: example-chart
    githubRelease:
      slug: example-org/other-name
      tag: v3.8.0
      assetNames: [\"components.yaml\"]"
VENDIR="${GIT_VENDIR}"
HELPERS_EXTRA=""

run_case append_to_existing_changed "## [Unreleased]

### Changed

- Update upstream example-chart chart to v3.7.3.
- Other change.

### Fixed

- A fix.

## [1.0.0] - 2026-01-01

### Changed

- Old." "## [Unreleased]

### Changed

- Update upstream example-chart chart to v3.7.3.
- Other change.
${E}

### Fixed

- A fix.

## [1.0.0] - 2026-01-01

### Changed

- Old."

run_case add_changed_when_missing "## [Unreleased]

### Added

- New thing.

## [1.0.0] - 2026-01-01

### Changed

- Old." "## [Unreleased]

### Added

- New thing.

### Changed

${E}

## [1.0.0] - 2026-01-01

### Changed

- Old."

run_case add_changed_between_added_and_fixed "## [Unreleased]

### Added

- New thing.

### Fixed

- A fix.

## [1.0.0] - 2026-01-01" "## [Unreleased]

### Added

- New thing.

### Changed

${E}

### Fixed

- A fix.

## [1.0.0] - 2026-01-01"

run_case add_changed_before_fixed "## [Unreleased]

### Fixed

- A fix." "## [Unreleased]

### Changed

${E}

### Fixed

- A fix."

run_case add_changed_after_added_at_eof "## [Unreleased]

### Added

- New thing." "## [Unreleased]

### Added

- New thing.

### Changed

${E}"

run_case empty_unreleased "## [Unreleased]

## [1.0.0] - 2026-01-01

- Old." "## [Unreleased]

### Changed

${E}

## [1.0.0] - 2026-01-01

- Old."

run_case changed_is_last_section "## [Unreleased]

### Fixed

- A fix.

### Changed

- Other change.

## [1.0.0] - 2026-01-01" "## [Unreleased]

### Fixed

- A fix.

### Changed

- Other change.
${E}

## [1.0.0] - 2026-01-01"

run_case changed_is_empty "## [Unreleased]

### Changed

### Fixed

- A fix." "## [Unreleased]

### Changed

${E}

### Fixed

- A fix."

run_case changed_at_eof "## [Unreleased]

### Changed

- Other change." "## [Unreleased]

### Changed

- Other change.
${E}"

run_case empty_changed_at_eof "## [Unreleased]

### Changed" "## [Unreleased]

### Changed

${E}"

run_case keeps_other_lines_untouched "## [Unreleased]

### Changed

- Item one.
  continued line.

- Item two.


### Fixed

- A fix." "## [Unreleased]

### Changed

- Item one.
  continued line.

- Item two.
${E}


### Fixed

- A fix."

run_case add_changed_before_link_references "## [Unreleased]

### Added

- New thing.

[Unreleased]: https://github.com/example-org/example/tree/main" "## [Unreleased]

### Added

- New thing.

### Changed

${E}

[Unreleased]: https://github.com/example-org/example/tree/main"

run_case append_to_changed_before_link_references "## [Unreleased]

### Changed

- Other change.

[Unreleased]: https://github.com/example-org/example/tree/main" "## [Unreleased]

### Changed

- Other change.
${E}

[Unreleased]: https://github.com/example-org/example/tree/main"

VENDIR="${RELEASE_VENDIR}"

run_case github_release_append "## [Unreleased]

### Changed

- Other change." "## [Unreleased]

### Changed

- Other change.
${E}"

run_case github_release_add_changed "## [Unreleased]

### Added

- New thing." "## [Unreleased]

### Added

- New thing.

### Changed

${E}"

HELPERS_EXTRA='UPSTREAM_NAME="custom-name" ; readonly UPSTREAM_NAME'

run_case helpers_override_name "## [Unreleased]

### Changed

- Other change." "## [Unreleased]

### Changed

- Other change.
- Update upstream custom-name chart to v3.8.0."

HELPERS_EXTRA=""

# an unknown vendir format must fail and leave the changelog as it was
repo="${WORK}/unknown_vendir_format"
mkdir -p "${repo}/sync"
git -C "${repo}" init -q
cp "${SCRIPT}" "$(dirname "${SCRIPT}")/_helpers.sh" "${repo}/sync/"
printf 'directories:\n- contents:\n  - path: example\n    helmChart:\n      name: example\n' > "${repo}/vendir.yml"
printf '## [Unreleased]\n' > "${repo}/CHANGELOG.md"
if (cd "${repo}" && ./sync/changelog.sh > /dev/null 2>&1); then
    echo "FAIL: unknown_vendir_format (script did not fail)" ; FAILS=$((FAILS + 1))
elif [ "$(cat "${repo}/CHANGELOG.md")" != "## [Unreleased]" ]; then
    echo "FAIL: unknown_vendir_format (changelog changed)" ; FAILS=$((FAILS + 1))
else
    echo "PASS: unknown_vendir_format"
fi

echo "failures: ${FAILS}"
[ "${FAILS}" -eq 0 ]
