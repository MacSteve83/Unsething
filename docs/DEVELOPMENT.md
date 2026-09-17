# Development and verification

## Source layout

- `Horos/`, `DCM Framework/`, `Nitrogen/`, `Preference Panes/`: application and inherited frameworks. Historical names remain for compatibility.
- `Horos/Sources/UnsethingQueryRetrieve/`: database adapters ported to current DCMTK, with class names distinct from the upstream implementation.
- `script/patches/`: DCMTK integration changes and the VTK repeated-buffer import fix.
- `DEPENDENCIES.lock.json`, `script/fetch_dependencies.py`: exact upstream snapshots, archive hashes and deterministic patch application.
- `Binaries/`: retained archive migration models, report resources and legacy helpers. Unused 3Dconnexion, homephone, Ming, Jasper and old FeedbackReporter binary archives have been removed from this publication copy.
- `script/tests/`: synthetic codec, imaging, DICOM and localization checks.

Downloaded sources, caches and build outputs are ignored by Git. The bootstrap refuses to overwrite existing unmarked dependency folders. When intentionally updating a dependency, update the lock and patch together; move the previous dependency folder aside before refetching. A matching marker permits local dependency edits without overwriting them.

## Verification commands

```sh
make
bash script/tests/run_updated_libraries.sh
bash script/tests/run_tls_smoke.sh

BUILD_ARCH=x86_64 BUILD_DATA=DerivedData-Intel make
BUILD_ARCH=x86_64 BUILD_DATA=DerivedData-Intel bash script/tests/run_updated_libraries.sh
BUILD_ARCH=x86_64 BUILD_DATA=DerivedData-Intel bash script/tests/run_tls_smoke.sh
```

The library checks compare OpenJPEG lossless pixel round trips (8/12/16-bit signed and unsigned), ITK/GDCM synthetic image data, VTK geometry and repeated volume imports, DCMTK SR references/ROI payloads and CT rescale behavior, and run the upstream CharLS tests. The TLS check uses temporary certificates and a loopback DICOM echo server.

`script/tests/run_library_smoke_app.sh` stages an app with a separate bundle identifier and a synthetic database under `DerivedData/LibrarySmoke`. Read the script before running; it starts a test DICOM listener. Use `SOURCE_APP` to select the app under test. It does not use a clinical database.

Historical upstream DICOM fixtures are not redistributed. Their optional legacy unit-test manifest is retained; those legacy fixture tests are not counted as passing when images are absent.

## Library migration

DCMTK patches preserve private ROI tags, SR references, per-series DICOMDIR icons, cancellation behavior, JPEG color preferences and legacy CT rescale compatibility. The C++ image class is named `DCMTKDicomImage` to avoid collision with the Objective-C model class. TLS code is adapted for OpenSSL 4.

VTK 9.7 needs an explicit tuple-count update after reusing a `vtkImageImport` buffer. Without it, subsequent updates can leave only one logical voxel. The patch and repeated-import regression check are included.

The migration was exercised on Apple Silicon and with Intel executables under Rosetta. Prior application smoke checks covered 2D, MPR, CPU/GPU MIP and volume rendering, including a real MR study. Automated networking checks covered C-ECHO, C-STORE, C-FIND and C-GET with synthetic data. No patient data from those checks is included here.

These are functional development checks, not a claim of complete clinical validation. The migrated libraries still need testing on physical Intel hardware and broader datasets. TLS verification covers the DCMTK tools, not every TLS setting in the application UI. The auxiliary `dciodvfy` binary and portable Weasis media viewer are older components; see their notices.

## Packaging

`make universal` merges architecture builds and generates an ad-hoc-signed test DMG of the full edition. It does not publish, sign with Developer ID, or notarize a release.

Distribution scripts require an explicit signing identity through `CERT` or `IDENTITY`. Prefer a locally configured `NOTARY_PROFILE` for notarization. Never commit credentials, certificates or private keys. Preserve the license and notice files with redistributed builds.

The checks performed specifically for the publication copy are listed in [VERIFICATION.md](VERIFICATION.md).
