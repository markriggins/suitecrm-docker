#!/bin/bash
# Patch History timeline adapter so audit descriptions render with trustHTML
# (plain innerHTML) instead of TinyMCE readonly editor, which often shows blank.
set -euo pipefail

ROOT="${1:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "usage: $0 /path/to/suitecrm/root" >&2
  exit 1
fi

patched=0

# Source (for future rebuilds / reference)
TS="${ROOT}/core/app/core/src/lib/containers/sidebar-widget/components/history-sidebar-widget/history-timeline.adapter.service.ts"
if [[ -f "$TS" ]] && ! grep -q 'trustHTML: true' "$TS"; then
  if grep -q "type: 'html'" "$TS" && grep -q "record.attributes.description" "$TS"; then
    perl -i -0pe "s/(timelineEntry\\.description = \\{\\n\\s*type: 'html',\\n\\s*value: record\\.attributes\\.description,\\n\\s*loading: signal\\(false\\),\\n\\s*display: signal\\('default'\\))\\n(\\s*\\};)/\$1,\\n                metadata: {trustHTML: true}\\n\$2/s" "$TS" || true
    if grep -q 'trustHTML: true' "$TS"; then
      echo "004: patched TS adapter"
      patched=1
    fi
  fi
fi

# Compiled main.*.js (what the browser actually loads)
shopt -s nullglob
for f in "${ROOT}/public/dist"/main.*.js; do
  base=$(basename "$f")
  # already patched
  if grep -q 'metadata:{trustHTML:!0}' "$f" 2>/dev/null; then
    echo "004: already applied in $base"
    continue
  fi
  if ! grep -q 'g.description={type:"html",value:t.attributes.description' "$f" 2>/dev/null; then
    continue
  fi
  perl -i -pe 's/g\.description=\{type:"html",value:t\.attributes\.description,loading:\(0,e\.signal\)\(!1\),display:\(0,e\.signal\)\("default"\)\}/g.description={type:"html",value:t.attributes.description,loading:(0,e.signal)(!1),display:(0,e.signal)("default"),metadata:{trustHTML:!0}}/g' "$f"
  if grep -q 'metadata:{trustHTML:!0}' "$f"; then
    # cache-bust: copy to new name and rewrite index.html refs
    newname="main.timeline-trusthtml.js"
    cp -a "$f" "${ROOT}/public/dist/${newname}"
    for idx in "${ROOT}/public/dist/index.html" "${ROOT}/public/index.html"; do
      if [[ -f "$idx" ]]; then
        sed -i "s/${base}/${newname}/g" "$idx"
      fi
    done
    echo "004: patched $base -> $newname"
    patched=1
  fi
done

if [[ "$patched" -eq 0 ]]; then
  echo "004: no changes needed (or pattern not found)"
fi
