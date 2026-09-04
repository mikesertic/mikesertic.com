#!/usr/bin/env bash
# Regenerates the Open Graph images (1200x630 JPEG) in /og from scripts/og-template.html using headless Chrome.
# Usage: ./scripts/build-og.sh   (run from the repo root; requires Google Chrome on macOS)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"

# name|eyebrow|line
PAGES=(
  "home|President, Advocates for Self-Government|Self-government as a practice, not just a principle."
  "about|About|Liberty education on one side, self-managed organizations on the other. One skill."
  "work|Work|Advocates for Self-Government. Political DNA. Students For Liberty. Morning Star."
  "speaking|Speaking|Keynotes, panels, podcasts, and workshops on self-government in practice."
  "press|Press kit|Bios, headshots, key facts, and past appearances. Use without asking."
  "newsletter|Newsletter|A short monthly letter on self-government in practice."
  "contact|Contact|Speaking, podcast, and press inquiries."
)

for entry in "${PAGES[@]}"; do
  IFS='|' read -r name eyebrow line <<< "$entry"
  html="$TMP/$name.html"
  python3 - "$ROOT/scripts/og-template.html" "$html" "$eyebrow" "$line" "$ROOT" <<'PY'
import sys, html
src, dst, eyebrow, line, root = sys.argv[1:6]
s = open(src).read()
s = s.replace('President, Advocates for Self-Government</div>', html.escape(eyebrow) + '</div>', 1)
s = s.replace('Self-government as a practice, not just a principle.</div>', html.escape(line) + '</div>', 1)
s = s.replace("url('../", "url('file://" + root + "/").replace('src="../', 'src="file://' + root + '/')
open(dst, 'w').write(s)
PY
  "$CHROME" --headless=new --no-sandbox --hide-scrollbars --window-size=1200,630 \
    --screenshot="$TMP/$name.png" "file://$html" >/dev/null 2>&1
  sips -s format jpeg -s formatOptions 88 "$TMP/$name.png" --out "$ROOT/og/$name.jpg" >/dev/null
  echo "wrote og/$name.jpg"
done
rm -rf "$TMP"
