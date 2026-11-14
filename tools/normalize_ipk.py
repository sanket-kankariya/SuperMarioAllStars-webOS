#!/usr/bin/env python3
"""
Normalizes an IPK (ar archive) for webOS installation:
- Standardizes entry timestamps
- Ensures directory and save folder permissions are 0777
- Sets executable bits (0755) on binaries and shared libraries
- Sets 0666 on data/config files
"""

import tarfile
import io
import gzip
import glob
import os
import sys

def normalize_ipk(ipk_path):
    print(f"Normalizing {ipk_path}...")
    now_ts = 1794524000
    entries = []
    with open(ipk_path, 'rb') as f:
        magic = f.read(8)
        if magic != b'!<arch>\n':
            print(f"Error: {ipk_path} is not a valid ar/ipk archive.")
            return False
        while True:
            hdr = f.read(60)
            if len(hdr) < 60:
                break
            name = hdr[:16].decode('ascii').strip()
            size = int(hdr[48:58].decode('ascii').strip())
            body = f.read(size)
            if size % 2 == 1:
                f.read(1)
            entries.append((name, body))

    out_entries = []
    for name, body in entries:
        if name in ('control.tar.gz', 'data.tar.gz'):
            tar_buf = io.BytesIO()
            with gzip.GzipFile(fileobj=tar_buf, mode='wb', mtime=now_ts) as gz:
                with tarfile.TarFile(fileobj=gz, mode='w') as tar:
                    with gzip.GzipFile(fileobj=io.BytesIO(body), mode='rb') as in_gz:
                        with tarfile.TarFile(fileobj=in_gz, mode='r') as in_tar:
                            for m in in_tar.getmembers():
                                content = in_tar.extractfile(m).read() if m.isreg() else None
                                m.mtime = now_ts
                                if m.name.endswith('boot') or m.name.endswith('SuperMarioAllStars') or '.so' in m.name:
                                    m.mode = 0o755
                                elif m.isdir() or 'saves' in m.name:
                                    m.mode = 0o777
                                else:
                                    m.mode = 0o666
                                tar.addfile(m, io.BytesIO(content) if content else None)
            out_entries.append((name, tar_buf.getvalue()))
        else:
            out_entries.append((name, body))

    with open(ipk_path, 'wb') as f:
        f.write(b'!<arch>\n')
        for name, body in out_entries:
            hdr_str = f"{name:<16}{now_ts:<12}{0:<6}{0:<6}{100644:<8}{len(body):<10}" + "`\n"
            assert len(hdr_str.encode('ascii')) == 60
            f.write(hdr_str.encode('ascii'))
            f.write(body)
            if len(body) % 2 == 1:
                f.write(b'\n')

    print(f"Successfully normalized {ipk_path} ({os.path.getsize(ipk_path)} bytes)")
    return True

if __name__ == '__main__':
    if len(sys.argv) > 1:
        ipk_files = [sys.argv[1]]
    else:
        search_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'out')
        ipk_files = glob.glob(os.path.join(search_dir, '*.ipk'))
    
    if not ipk_files:
        print("No IPK files found to normalize.")
        sys.exit(1)

    for p in ipk_files:
        normalize_ipk(p)
