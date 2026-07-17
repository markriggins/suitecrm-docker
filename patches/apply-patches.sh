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
  local plug_dir="${ROOT}/public/legacy/custom/include/Smarty/plugins"
  mkdir -p "$plug_dir"
  cp -f "${SCRIPT_DIR}/001-smarty-file_exists/modifier.file_exists.php" \
    "${plug_dir}/modifier.file_exists.php"
  log "001: installed custom modifier.file_exists.php"
}

patch_002_php_error_display() {
  :
}

# ── patch-003: Timeline audit shows text field values ──────────────────────
patch_003_timeline_audit_text_values() {
  local f="${ROOT}/core/backend/Data/LegacyHandler/PresetDataHandlers/HistoryTimelineDataHandler.php"
  if [[ ! -f "$f" ]]; then
    log "skip 003: HistoryTimelineDataHandler.php not found"
    return 0
  fi
  if grep -q 'COALESCE(NULLIF(after_value_string' "$f"; then
    log "003: already applied"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 "${SCRIPT_DIR}/003-timeline-audit-text/patch.py" "$f" && log "003: timeline audit text values" && return 0
  fi
  log "skip 003: python3 required to apply"
}

# ── patch-004: Timeline audit HTML uses trustHTML (not TinyMCE) ───────────
patch_004_timeline_audit_trusthtml() {
  local script="${SCRIPT_DIR}/004-timeline-audit-trusthtml/patch.sh"
  if [[ ! -f "$script" ]]; then
    log "skip 004: patch.sh missing"
    return 0
  fi
  bash "$script" "$ROOT" && log "004: timeline audit trustHTML" || log "004: failed"
}

log "applying engine patches to ${ROOT}"
patch_001_smarty_file_exists
patch_002_php_error_display
patch_003_timeline_audit_text_values
patch_004_timeline_audit_trusthtml
log "done"
