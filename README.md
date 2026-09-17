# Unsething

**A macOS DICOM viewer for Intel and Apple Silicon.**

Unsething brings together study management, DICOM networking, 2D viewing, MPR and 3D volume rendering. Local archives on internal and external disks appear in **Sources**, making it possible to switch databases and copy patients between them.

[Website](https://unsething.it) · [Changes](Changelog.md) · [Build and test details](docs/DEVELOPMENT.md)

## Project origin

Unsething is derived from **Horos**, which was originally based on **OsiriX**. It carries forward that open-source code with Unsething's interface, archive discovery, localization and compatibility changes. Original copyright notices are retained. See [NOTICE](NOTICE), [LICENSE](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES.md).

This repository contains the **development source based on Unsething 1.2.2, with the library migration**. It is not a claim that this commit reproduces an earlier signed 1.2.2 installer. No signed installer is published by this source import.

## Features

- DICOM import, export, query/retrieve and send.
- Local archive discovery, including existing `Horos Data` and `OsiriX Data` archives.
- 2D viewer, multiplanar reconstruction and CPU/GPU volume rendering.
- Italian and English interface, including default albums, About and release notes.
- Builds for Apple Silicon (`arm64`) and Intel (`x86_64`).

**No application plugins or plugin packages are included.** The plugin manager and compatibility APIs remain part of the host application. Historical source paths such as `Horos/` are retained where needed for build and API compatibility.

## Build

You need macOS, full Xcode with its command-line tools selected, Python 3.9 or later, CMake and pkg-config. The local verification toolchain uses Xcode 26.6, CMake 3.31.6 and pkg-config 0.29.2. Keep CMake on the 3.x series for these legacy build scripts. Apple Silicon builds also require Rosetta for the bundled Intel-only DICOM validation helper. DMG creation additionally needs Python with Pillow.

```sh
git clone https://github.com/MacSteve83/Unsething.git
cd Unsething
make
```

`make` builds for the current Mac's architecture, without launching or closing Unsething. It first downloads the exact upstream snapshots in [DEPENDENCIES.lock.json](DEPENDENCIES.lock.json), checks SHA-256 hashes and applies the source patches in `script/patches/`. No submodule checkout is needed. The first build needs network access and several gigabytes of disk space; subsequent builds reuse the local sources and build outputs.

The app is written to `DerivedData/Build/Products/Debug/Unsething.app` and signed locally ad hoc. An Apple Developer account is not required for this local build.

```sh
# Explicit Intel build, with separate outputs
BUILD_ARCH=x86_64 BUILD_DATA=DerivedData-Intel make

# Full universal build and test DMG (Apple Silicon build host)
make universal

# Compile and launch; this closes an existing Unsething instance first
make run
```

The universal packaging script is intended for an Apple Silicon host with Rosetta. Native single-architecture builds can be made on the corresponding architecture. These scripts do not notarize the app. Distribution signing requires the builder's own Developer ID and notarization credentials, supplied outside the repository.

For Xcode: run `python3 script/fetch_dependencies.py`, open `Unsething.xcodeproj`, select the `Unsething` scheme and set `SKIP_SUBMODULES=1`. For unsigned local builds also set `CODE_SIGNING_ALLOWED=NO`, `CODE_SIGNING_REQUIRED=NO`, `CODE_SIGN_IDENTITY=` and `DEVELOPMENT_TEAM=`. The command-line build sets these automatically.

## Dependencies

| Component | Pinned version |
| --- | --- |
| OpenSSL | 4.0.2 |
| DCMTK | 3.7.0, with Unsething patches |
| GDCM | 3.2.7 |
| ITK | 5.4.7 |
| VTK | 9.7.0, with repeated-volume-import fix |
| OpenJPEG | 2.5.4 |
| CharLS | 2.4.4 |
| FeedbackReporter | `92230feade69e1298cd5a8cbc0c8ddd2dc939934` |

JPEG 2000 uses **OpenJPEG**. Grok is not included or linked. The separately bundled legacy helpers and their versions are documented in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md); the table above does not mean every historical auxiliary has been updated.

## Tests and contributions

After building, run `bash script/tests/run_updated_libraries.sh` and `bash script/tests/run_tls_smoke.sh`. See [development notes](docs/DEVELOPMENT.md) for architecture selection, isolated application tests and current validation limits.

Please include your macOS version, CPU architecture, build command and reproduction steps in bug reports. Use synthetic or appropriately anonymized test data. Do not upload patient archives, identifiable screenshots, credentials or signing certificates to issues or pull requests.

## License

The Horos-derived application is distributed under **GNU LGPL version 3**; individual third-party components retain their own licenses. [LICENSE](LICENSE) includes LGPLv3 and the incorporated GPLv3 terms. [LICENSES/](LICENSES/) contains additional notices; source-file headers and upstream dependency notices are retained.
