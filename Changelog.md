# Changes

## Development — library migration

- Updated OpenSSL, DCMTK, GDCM, ITK, VTK, OpenJPEG and CharLS; exact versions and hashes are in `DEPENDENCIES.lock.json`.
- Ported DICOM/database adapters and preserved ROI, SR, JPEG and CT compatibility behavior.
- Fixed repeated VTK volume imports and applied toolbar sizing to 3D controllers.
- Added reproducible dependency fetching, patches and synthetic regression checks.
- Prepared public sources without application plugins or unused legacy binary dependencies.

This development snapshot has not been promoted to a new signed release.

## Unsething 1.2.2

- Database fixes: recognize and open existing Horos and OsiriX archives without creating a nested empty Unsething database; report opening errors.
- Show version 1.2.2 consistently in About.
- Localize default albums, About, descriptions and release notes in Italian and English.
- Show a restart notice in the newly selected language.

## Unsething 1.2.1

- Discover databases on internal and removable disks in Sources; switch archives and copy patients by drag and drop.
- Graphics fixes: toolbar sizing, filters, alignment and application/source icons.
- Italian selected by default for new installations.
- Default example DICOM node: AE Title `unsething`, port `11112`.
- Universal builds for Intel and Apple Silicon.

## Upstream history

The inherited Horos changelog recorded 4.0.0 RC5: Apple Silicon support, third-party library updates, 2D rendering and toolbar fixes, and removal of 3Dconnexion and homephone support. This is historical provenance, not an Unsething version number.
