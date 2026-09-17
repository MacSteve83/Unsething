#!/usr/bin/env python3
"""Generate a small synthetic CT sphere for testing the 2D/3D viewer."""
from pathlib import Path
import subprocess
import sys
root = Path(__file__).resolve().parents[2]
output = Path(sys.argv[1])
output.mkdir(parents=True, exist_ok=True)
tool = root / 'DerivedData/Build/Intermediates.noindex/Unsething.build/Debug/DCMTK.build/Install/bin/dump2dcm'
for z in range(32):
    pixels = []
    for y in range(32):
        for x in range(32):
            radius = ((x-15.5)**2 + (y-15.5)**2 + (z-15.5)**2)**0.5
            value = 2200 if radius < 5 else 1300 if radius < 11 else 0
            pixels.append(f'{value:04x}')
    header = f'''(0008,0016) UI =CTImageStorage
(0008,0018) UI [1.2.826.0.1.3680043.10.999.22.{z+1}]
(0008,0020) DA [20260914]
(0008,0030) TM [120000]
(0008,0060) CS [CT]
(0008,1030) LO [Synthetic volume library test]
(0008,103e) LO [Synthetic sphere]
(0010,0010) PN [SYNTHETIC^VOLUME]
(0010,0020) LO [SYNTHETIC-VOLUME]
(0018,0050) DS [1]
(0020,000d) UI [1.2.826.0.1.3680043.10.999.20]
(0020,000e) UI [1.2.826.0.1.3680043.10.999.21]
(0020,0011) IS [1]
(0020,0013) IS [{z+1}]
(0020,0032) DS [0\\0\\{z}]
(0020,0037) DS [1\\0\\0\\0\\1\\0]
(0020,0052) UI [1.2.826.0.1.3680043.10.999.23]
(0028,0002) US 1
(0028,0004) CS [MONOCHROME2]
(0028,0010) US 32
(0028,0011) US 32
(0028,0030) DS [1\\1]
(0028,0100) US 16
(0028,0101) US 12
(0028,0102) US 11
(0028,0103) US 0
(0028,1050) DS [500]
(0028,1051) DS [2500]
(0028,1052) DS [-1024]
(0028,1053) DS [1]
'''
    dump = output / f'slice-{z:02d}.dump'
    dump.write_text(header + '(7fe0,0010) OW ' + '\\'.join(pixels) + '\n')
    subprocess.run([str(tool), '+l', '16384', '+te', str(dump), str(dump.with_suffix('.dcm'))], check=True, stdout=subprocess.DEVNULL)
    if not dump.with_suffix('.dcm').is_file():
        raise RuntimeError('dump2dcm did not generate a DICOM file')
    dump.unlink()
print(f'Generated 32 synthetic CT slices in {output}')
