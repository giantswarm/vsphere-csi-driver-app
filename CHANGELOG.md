# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Update upstream chart to `v3.3.1`
- Make deployment `affinity` and `tolerations` configurable in `values.yaml`.

## [3.4.2] - 2025-03-17

### Fixed

- Correct kubectl image tag.

### Removed

- Remove superfluous update script.

## [3.4.1] - 2025-03-10

### Changed

- Update CircleCI config.

## [3.4.0] - 2025-03-10

### Added

- Add upstream chart at `v3.3.0`.
- Add repo scaffolding to generate the chart.

[Unreleased]: https://github.com/giantswarm/vsphere-csi-driver-app/compare/v3.4.2...HEAD
[3.4.2]: https://github.com/giantswarm/vsphere-csi-driver-app/compare/v3.4.1...v3.4.2
[3.4.1]: https://github.com/giantswarm/vsphere-csi-driver-app/compare/v3.4.0...v3.4.1
[3.4.0]: https://github.com/giantswarm/vsphere-csi-driver-app/releases/tag/v3.4.0
