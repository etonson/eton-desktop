#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
[[ ${1:-} == "" || ${1:-} == --dry-run ]] || { printf 'Usage: %s [--dry-run]\n' "$0" >&2; exit 2; }
resolve_target
active_backup
check_target_identity
expected="$(cat -- "$BACKUP_DIR/applied.sha256")"
actual="$(hash_file "$CONFIG_TARGET")"
[[ "$actual" == "$expected" ]] || { printf 'WezTerm differs from applied snapshot.\n' >&2; exit 1; }
rg -q '^config\.window_background_opacity = 0\.96' "$CONFIG_TARGET"
rg -q '^-- FOREST-RETREAT-COLORS-BEGIN$' "$CONFIG_TARGET"
printf 'Verified file content and hash: %s\n' "$CONFIG_TARGET"
if [[ -f "$BACKUP_DIR/wallpaper.after.picture-uri" ]]; then
  "$PROJECT_DIR/scripts/wallpaper.sh" verify
fi
printf 'Visual checks still needed in GNOME Wayland: WezTerm text contrast, transparency, Dock, Overview, Firefox and IntelliJ.\n'
