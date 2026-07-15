#!/bin/bash
# Apply all engine patches under patches/ to a SuiteCRM tree.
# Usage: apply-patches.sh /path/to/suitecrm/root
# Idempotent. Called at image build (seed) and container start (volume).
set -euo pipefail

ROOT="${1:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "usage: $0 /path/to/suitecrm/root" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
log() { echo "[patches] $*"; }

# ── patch-001: Smarty file_exists (SuiteCRM 8.10 + Smarty 5) ──────────────
# Core themes/suite8/tpls/header.tpl uses {if file_exists(...)}.
# Smarty 5 deprecates unregistered PHP functions in templates.
patch_001_smarty_file_exists() {
  local sm="${ROOT}/public/legacy/include/Sugar_Smarty.php"
  if [[ ! -f "$sm" ]]; then
    log "skip 001: Sugar_Smarty.php not found"
    return 0
  fi
  if ! grep -q 'registerPlugin("modifier", "file_exists"' "$sm"; then
    sed -i 's/$this->registerPlugin("modifier", "key", "key");/$this->registerPlugin("modifier", "key", "key");\n        $this->registerPlugin("modifier", "file_exists", "file_exists");/' "$sm"
    log "001: registered file_exists modifier"
  fi
  if ! grep -q "'file_exists'" "$sm"; then
    sed -i "s/'count',/'count',\n            'file_exists',/" "$sm"
    log "001: added file_exists to registerPHPFunctions"
  fi
  # Custom Smarty plugin (loaded when custom/include/Smarty/plugins exists)
  local plug_dir="${ROOT}/public/legacy/custom/include/Smarty/plugins"
  mkdir -p "$plug_dir"
  cp -f "${SCRIPT_DIR}/001-smarty-file_exists/modifier.file_exists.php" \
    "${plug_dir}/modifier.file_exists.php"
  log "001: installed custom modifier.file_exists.php"
}

# ── patch-002: PHP do not display deprecations ─────────────────────────────
# Applied at image level via conf.d; no-op here if already set.
patch_002_php_error_display() {
  # Entrypoint may run without write to /usr/local/etc; Dockerfile owns this.
  :
}

log "applying engine patches to ${ROOT}"
patch_001_smarty_file_exists
patch_002_php_error_display
log "done"
