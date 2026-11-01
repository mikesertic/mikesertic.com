#!/usr/bin/env python3
"""Checks that every inline <script> in the HTML pages is allowed by the CSP in vercel.json.

The CSP allows inline scripts by SHA-256 hash, so any edit to an inline script (even whitespace)
silently blocks it in the browser. Run this after touching a <script> block:

    python3 -I scripts/check-csp.py

Exit code is non-zero when a hash is missing; the output shows the value to paste into vercel.json.
"""
import base64, glob, hashlib, json, os, re, sys

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cfg = json.load(open(os.path.join(root, 'vercel.json')))
csp = next(h['value'] for rule in cfg['headers'] if rule['source'] == '/(.*)'
           for h in rule['headers'] if h['key'] == 'Content-Security-Policy')
allowed = set(re.findall(r"'(sha256-[^']+)'", csp))

seen, missing = {}, {}
for page in sorted(glob.glob(os.path.join(root, '*.html'))):
    html = open(page, encoding='utf-8').read()
    for m in re.finditer(r'<script(?P<attrs>[^>]*)>(?P<body>.*?)</script>', html, re.S):
        if 'src=' in m.group('attrs') or 'ld+json' in m.group('attrs'):
            continue
        digest = 'sha256-' + base64.b64encode(hashlib.sha256(m.group('body').encode('utf-8')).digest()).decode()
        seen.setdefault(digest, []).append(os.path.basename(page))
        if digest not in allowed:
            missing.setdefault(digest, []).append(os.path.basename(page))

for digest, pages in missing.items():
    print(f"MISSING from CSP: '{digest}'  (used in {', '.join(sorted(set(pages)))})")
for digest in allowed - set(seen):
    print(f"UNUSED in CSP (safe to remove): '{digest}'")
if missing:
    sys.exit(1)
print(f"OK: {len(seen)} inline script hash(es) all present in vercel.json")
