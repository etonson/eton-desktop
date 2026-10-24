#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
require_user
[[ ${1:-} == "" || ${1:-} == --dry-run ]] || { printf 'Usage: %s [--dry-run]\n' "$0" >&2; exit 2; }
resolve_target
printf 'Planned change: %s\n' "$CONFIG_TARGET"
printf '  colors: current palette -> Everforest Dark Medium\n  window_background_opacity: current value -> 0.96\n'
printf 'GNOME theme, icons, extensions, wallpaper, font and default terminal: no changes\n'
candidate="$(mktemp)"
trap 'rm -f -- "$candidate"' EXIT
python3 "$PROJECT_DIR/scripts/wezterm_merge.py" "$CONFIG_TARGET" "$PROJECT_DIR/config/wezterm.lua" "$candidate"
if cmp -s -- "$CONFIG_TARGET" "$candidate"; then printf 'Already up to date.\n'; exit 0; fi
diff -u -- "$CONFIG_TARGET" "$candidate" || [[ $? -eq 1 ]]
if [[ ${1:-} == --dry-run ]]; then exit 0; fi
active_backup
check_target_identity
current_hash="$(hash_file "$CONFIG_TARGET")"
original_hash="$(cat -- "$BACKUP_DIR/original.sha256")"
if [[ "$current_hash" != "$original_hash" ]]; then
  printf 'Conflict: WezTerm config changed since backup; refusing to overwrite.\n' >&2
  exit 1
fi
python3 - "$candidate" "$CONFIG_TARGET" <<'PY'
from pathlib import Path
import os, shutil, stat, sys, tempfile
source, target = Path(sys.argv[1]), Path(sys.argv[2])
mode = stat.S_IMODE(target.stat().st_mode)
fd, temp = tempfile.mkstemp(prefix='.forest-retreat-', dir=target.parent)
try:
    with os.fdopen(fd, 'wb') as out, source.open('rb') as inp:
        shutil.copyfileobj(inp, out)
        out.flush()
        os.fsync(out.fileno())
    os.chmod(temp, mode)
    os.replace(temp, target)
except BaseException:
    if os.path.exists(temp): os.unlink(temp)
    raise
PY
hash_file "$CONFIG_TARGET" > "$BACKUP_DIR/applied.sha256"
printf 'Applied. Backup: %s\n' "$BACKUP_DIR"
