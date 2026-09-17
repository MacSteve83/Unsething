"""Merge independently built app bundles, verifying every Mach-O architecture."""
from pathlib import Path
import shutil
import subprocess
import sys

arm, intel, output = map(Path, sys.argv[1:])
magic = {bytes.fromhex(h) for h in ('feedface', 'cefaedfe', 'feedfacf', 'cffaedfe', 'cafebabe', 'bebafeca', 'cafebabf', 'bfbafeca')}
def binaries(root):
    result = set()
    for path in root.rglob('*'):
        if path.is_symlink() or not path.is_file():
            continue
        with path.open('rb') as f:
            if f.read(4) in magic:
                result.add(path.relative_to(root))
    return result

def archs(path):
    return set(subprocess.check_output(['lipo', '-archs', str(path)], text=True).split())

# Existing auxiliary binaries shipped by this legacy project are Intel-only.
# Keep identical copies; the main app and its native frameworks must be universal.
legacy = {
    Path('Contents/Frameworks/3DconnexionClient.framework/Versions/A/3DconnexionClient'),
    Path('Contents/Frameworks/homephone.framework/Versions/A/homephone'),
    *[Path('Contents/Resources') / name for name in
      ('dciodvfy', 'dsr2html', 'dcmpsprt', 'dcmdump', 'dcmprscu', 'echoscu')],
}
arm_files, intel_files = binaries(arm), binaries(intel)
if arm_files != intel_files:
    raise SystemExit(f'Binary bundle mismatch: {arm_files ^ intel_files}')
if output.exists():
    shutil.rmtree(output)
subprocess.run(['ditto', str(arm), str(output)], check=True)
for rel in sorted(arm_files):
    a, i, dest = arm / rel, intel / rel, output / rel
    if 'arm64' not in archs(a) and rel in legacy and archs(a) == archs(i):
        print(f'Existing Intel auxiliary component retained: {rel}')
        continue
    if not {'arm64', 'x86_64'} <= archs(a):
        if 'arm64' not in archs(a) or 'x86_64' not in archs(i):
            raise SystemExit(f'Missing required architecture: {rel}')
        tmpa, tmpi = dest.with_name(dest.name + '.arm'), dest.with_name(dest.name + '.intel')
        for src, tmp, architecture in ((a, tmpa, 'arm64'), (i, tmpi, 'x86_64')):
            if len(archs(src)) > 1:
                subprocess.run(['lipo', str(src), '-thin', architecture, '-output', str(tmp)], check=True)
            else:
                shutil.copy2(src, tmp)
        subprocess.run(['lipo', '-create', str(tmpa), str(tmpi), '-output', str(dest)], check=True)
        tmpa.unlink()
        tmpi.unlink()
    if not {'arm64', 'x86_64'} <= archs(dest):
        raise SystemExit(f'Invalid universal binary: {rel}')
print('PASS: app and native frameworks are universal; legacy auxiliary components retained')
