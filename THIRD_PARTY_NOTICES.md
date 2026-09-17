# Third-party notices

Unsething is derived from Horos, originally based on OsiriX. Copyright notices and license headers in inherited source files remain intact. [NOTICE](NOTICE) explains the provenance and modifications. [LICENSE](LICENSE) contains LGPLv3; the incorporated GPLv3 terms are in [LICENSES/GPL-3.0.txt](LICENSES/GPL-3.0.txt). The historical combined text is preserved in [LICENSES/Horos-LGPL-GPL-original.txt](LICENSES/Horos-LGPL-GPL-original.txt).

This index describes the current development build. It does not replace individual component licenses or the notices embedded in upstream sources and archives.

## Downloaded and compiled dependencies

Exact official repositories, revisions, archive URLs and SHA-256 hashes are recorded in [DEPENDENCIES.lock.json](DEPENDENCIES.lock.json). `script/fetch_dependencies.py` retrieves those snapshots and applies the included patches. Their full source trees, including nested third-party notices, remain available after bootstrap.

| Component | Version | License / notice copy | Role |
| --- | --- | --- | --- |
| OpenSSL | 4.0.2 | [Apache 2.0](LICENSES/OpenSSL.txt) | TLS and cryptography |
| DCMTK | 3.7.0, modified | [DCMTK copyright and bundled-component terms](LICENSES/DCMTK.txt) | DICOM networking, images, SR and command-line tools |
| GDCM | 3.2.7 | [GDCM copyright](LICENSES/GDCM.txt) | DICOM image handling |
| ITK | 5.4.7 | [Apache 2.0](LICENSES/ITK.txt), [NOTICE](LICENSES/ITK-NOTICE.txt) | Image processing |
| VTK | 9.7.0, modified | [BSD-style terms](LICENSES/VTK.txt) | Visualization and reconstruction |
| OpenJPEG | 2.5.4 | [BSD-style terms](LICENSES/OpenJPEG.txt) | JPEG 2000 |
| CharLS | 2.4.4 | [BSD 3-Clause](LICENSES/CharLS.txt) | JPEG-LS |
| FeedbackReporter | `92230feade69e1298cd5a8cbc0c8ddd2dc939934` | [Apache 2.0](LICENSES/FeedbackReporter.txt) | Inherited feedback framework |

DCMTK and VTK modifications are supplied as source patches in `script/patches/`. Code bundled inside these projects retains its respective licenses. The build copies the notices collected from downloaded dependencies into the application's `Contents/Resources/Licenses` folder, together with this index and the application license.

**Grok is not present or linked.** References to Grok in [the preserved historical upstream notice](LICENSES/Horos-upstream-NOTICE.txt) describe that earlier Horos build. Unsething uses OpenJPEG.

## Other inherited source components

- `cocoahttpserver`: [BSD-style license](LICENSES/cocoahttpserver.txt).
- `NIfTI_Library`: public-domain NIfTI code and the accompanying `znzlib` terms, as retained in source headers.
- `DCM Framework`, `Nitrogen`, `MSRG`, `LetsMoveAndDock`, `NSFont_OpenGL`, `Papyrus3`, preference panes and other inherited utilities: original per-file author and license notices remain in the source. The umbrella application license does not replace more specific notices.
- `Binaries/dcmtk-source`: historical source retained with its notices and Xcode navigation references. The active DICOM library is the modern `DCMTK` snapshot and the ported Unsething adapters.

## Retained binary helpers and resources

### dciodvfy / dicom3tools

`Binaries/dciodvfy.zip` contains the inherited Intel-only DICOM validation helper, reporting `1.00.snapshot.20191225051647`. It is not one of the newly updated libraries. Apple Silicon executes this helper through Rosetta.

Author: David A. Clunie / PixelMed Publishing. [BSD-style copyright and disclaimer](LICENSES/dicom3tools-COPYRIGHT.txt), from the [official dicom3tools site](https://dclunie.com/dicom3tools.html). Source packages are available in the author's [source archive](https://dclunie.com/dicom3tools/workinprogress/index.html). The reproduced copyright is the notice currently published by the author; it does not imply that the bundled binary was rebuilt from the latest source.

### Weasis portable 3.6.0

`Binaries/weasis-portable-3.6.0.zip` is the inherited standalone viewer used for portable media export. It is not an Unsething application plugin and has not been upgraded in this migration.

The archive includes its own `Licence.txt`, reproduced in [LICENSES](LICENSES/Weasis-portable-3.6.0-Licence.txt), plus licenses/notices in its Java components. Source for that release is available at [nroduit/Weasis, tag v3.6.0](https://github.com/nroduit/Weasis/tree/v3.6.0). Keep the archive's component notices with redistributed media. The build removes the empty legacy macOS launcher bundle as in the inherited packaging flow.

### Archive models and report templates

`Binaries/DB_Previous_Models.zip`, `Binaries/PAGES.zip`, `Binaries/OsiriXReport.template.zip` and report template resources are inherited migration/template assets. Their historical names are preserved for compatibility.

Unused homephone, 3Dconnexion, Ming, Jasper and prebuilt FeedbackReporter archives are excluded from this publication copy. No Unsething/Horos/OsiriX application plugin source or compiled plugin is distributed here; the host's plugin APIs remain available.

## Names and redistribution

Horos, OsiriX and other upstream names identify provenance or compatibility. Unsething is not presented as an official release or endorsement of those projects. Keep original notices, applicable licenses and the corresponding source/patches with redistribution as required by each component's terms.
