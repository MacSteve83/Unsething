# Public source preparation checks

The publication copy was checked independently of the existing working sources.

- Dependency archives matched their pinned SHA-256 hashes. After applying patches, dependency source files matched the tested library-migration tree.
- A fresh local Git clone successfully bootstrapped all eight dependency snapshots, applied the DCMTK/VTK patches and extracted all seven legacy database migration models. Resource extraction now happens before Xcode plans the build.
- Application builds succeeded for arm64 and x86_64. The universal merge and deep/strict ad-hoc signature verification succeeded. The legacy `dciodvfy` auxiliary remains Intel-only, as documented.
- Codec, image-processing, VTK, DCMTK and CharLS checks passed for both architectures. Intel executables were tested through Rosetta, not on physical Intel hardware.
- Mutually authenticated loopback DICOM TLS echo passed for both architectures using disposable certificates.
- Legacy database path regression checks passed, alongside 110 default-album localization checks.
- The Git file list was checked for embedded application plugins, DICOM files, generated build directories, signing material, common credential patterns and local author configuration. None of the checked excluded files/patterns remained. Maintained documentation links resolved locally.
- The prepared bundle contains application and third-party license notices.

A new interactive UI smoke test could not be completed because the Mac was locked. The isolated test app was stopped; its DICOM listener did not become ready before that stop. This attempt is not counted as a passed application/network smoke test. Earlier migration smoke checks are described separately in [DEVELOPMENT.md](DEVELOPMENT.md).

This document records local development checks, not a published release or notarization. GitHub publication requires an authenticated maintainer session.
