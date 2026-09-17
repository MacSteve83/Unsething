#!/usr/bin/env python3
"""Fetch checksum-pinned upstream snapshots and apply the repository's patches."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / 'DEPENDENCIES.lock.json'

def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''): h.update(chunk)
    return h.hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cache-dir', type=Path, default=ROOT / '.dependency-cache')
    args = parser.parse_args()
    args.cache_dir.mkdir(parents=True, exist_ok=True)
    specs = json.loads(LOCK.read_text())
    for name, spec in specs.items():
        patches = [ROOT / p for p in spec.get('patches', [])]
        stamp = {'sha256': spec['sha256'], 'patches': {str(p.relative_to(ROOT)): digest(p) for p in patches}}
        target = ROOT / name
        marker = target / '.unsething-source.json'
        if marker.exists() and json.loads(marker.read_text()) == stamp:
            print(name + ': ready', flush=True)
            continue
        if target.exists():
            raise SystemExit(str(target) + ': existing sources differ or have no marker; move them aside before fetching. No files overwritten.')
        archive = args.cache_dir / (name + '-' + spec['sha256'][:16] + '.tar.gz')
        if not archive.exists():
            print('Downloading ' + name + ' ' + spec['ref'], flush=True)
            temporary = archive.with_suffix('.partial')
            req = urllib.request.Request(spec['url'], headers={'User-Agent': 'Unsething-source-bootstrap'})
            with urllib.request.urlopen(req, timeout=120) as response, temporary.open('wb') as out:
                shutil.copyfileobj(response, out)
            if digest(temporary) != spec['sha256']:
                temporary.unlink()
                raise SystemExit(name + ': archive checksum mismatch')
            temporary.replace(archive)
        if digest(archive) != spec['sha256']:
            raise SystemExit(str(archive) + ': archive checksum mismatch; remove this cache file and retry')
        with tempfile.TemporaryDirectory(prefix='.dependency-extract-', dir=str(ROOT)) as td:
            base = Path(td).resolve()
            with tarfile.open(archive) as tf:
                for entry in tf.getmembers():
                    path = (base / entry.name).resolve()
                    if os.path.commonpath([str(base), str(path)]) != str(base):
                        raise SystemExit('Unsafe archive path: ' + entry.name)
                    if entry.isdev() or entry.isfifo(): raise SystemExit('Unsupported archive entry: ' + entry.name)
                    if entry.issym() or entry.islnk():
                        link = ((path.parent if entry.issym() else base) / entry.linkname).resolve()
                        if os.path.commonpath([str(base), str(link)]) != str(base):
                            raise SystemExit('Unsafe archive link: ' + entry.name)
                tf.extractall(base)
            roots = list(base.iterdir())
            if len(roots) != 1 or not roots[0].is_dir(): raise SystemExit(name + ': unexpected archive layout')
            unpacked = roots[0]
            for patch in patches:
                subprocess.run(['patch', '--batch', '-p1', '-i', str(patch)], cwd=str(unpacked), check=True)
            (unpacked / '.unsething-source.json').write_text(json.dumps(stamp, indent=2) + '\n')
            unpacked.rename(target)
        print(name + ': verified and prepared', flush=True)

def prepare_bundled_resources():
    # Xcode checks source inputs while planning the build, before dependency
    # script phases run. Unpack migration models before invoking xcodebuild.
    env = dict(os.environ, SRCROOT=str(ROOT))
    subprocess.run(['bash', str(ROOT / 'Horos/Scripts/Horos/Unzip.sh')], env=env, check=True)
    print('Bundled resources: ready', flush=True)

if __name__ == '__main__':
    main()
    prepare_bundled_resources()
