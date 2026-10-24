#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SOURCE_IMAGE="$PROJECT_DIR/assets/rowan-heuvel-misty-lake.jpg"
INSTALLED_IMAGE="${XDG_DATA_HOME:-$HOME/.local/share}/forest-retreat/wallpapers/rowan-heuvel-misty-lake.jpg"
SCHEMA=org.gnome.desktop.background
KEYS=(picture-uri picture-uri-dark picture-options)

usage() { printf 'Usage: %s {backup|apply|verify|rollback} [--dry-run]\n' "$0" >&2; exit 2; }
[[ $# -ge 1 && $# -le 2 ]] || usage
COMMAND=$1
[[ "$COMMAND" == backup || "$COMMAND" == apply || "$COMMAND" == verify || "$COMMAND" == rollback ]] || usage
[[ $# -eq 1 || $2 == --dry-run ]] || usage
DRY_RUN=${2:-}
if [[ "$COMMAND" != verify ]]; then require_user; fi
active_backup

expected_source_hash="$(cut -d ' ' -f 1 "$PROJECT_DIR/assets/SOURCE.sha256")"
[[ "$(hash_file "$SOURCE_IMAGE")" == "$expected_source_hash" ]] || {
  printf 'Wallpaper asset checksum mismatch.\n' >&2; exit 1;
}
uri="$(python3 - "$INSTALLED_IMAGE" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).absolute().as_uri())
PY
)"

read_current() { gsettings get "$SCHEMA" "$1"; }
saved() { cat -- "$BACKUP_DIR/wallpaper.before.$1"; }
expected_after() {
  if [[ "$1" == picture-options ]]; then printf "'zoom'"; else printf "'%s'" "$uri"; fi
}
check_backup() {
  for key in "${KEYS[@]}"; do
    [[ -f "$BACKUP_DIR/wallpaper.before.$key" && -f "$BACKUP_DIR/wallpaper.user.$key" ]] || {
      printf 'Missing wallpaper backup for %s; run wallpaper.sh backup.\n' "$key" >&2; exit 1;
    }
  done
}
check_original_image() {
  if [[ -f "$BACKUP_DIR/wallpaper.previous.sha256" ]]; then
    local original_path original_hash
    original_path="$(cat -- "$BACKUP_DIR/wallpaper.previous.path")"
    original_hash="$(cat -- "$BACKUP_DIR/wallpaper.previous.sha256")"
    [[ -f "$original_path" && "$(hash_file "$original_path")" == "$original_hash" ]] || {
      printf 'Conflict: prior wallpaper file changed or disappeared: %s\n' "$original_path" >&2
      printf 'Its saved copy is %s/wallpaper.previous\n' "$BACKUP_DIR" >&2
      exit 1
    }
  fi
}

case "$COMMAND" in
  backup)
    printf 'Will back up GNOME picture-uri, picture-uri-dark, picture-options, and current image if local.\n'
    printf 'Backup directory: %s\n' "$BACKUP_DIR"
    if [[ -f "$BACKUP_DIR/wallpaper.before.picture-uri" ]]; then
      printf 'Wallpaper backup already exists.\n'; exit 0
    fi
    if [[ "$DRY_RUN" == --dry-run ]]; then exit 0; fi
    umask 077
    for key in "${KEYS[@]}"; do
      read_current "$key" > "$BACKUP_DIR/wallpaper.before.$key"
      dconf read "/org/gnome/desktop/background/$key" > "$BACKUP_DIR/wallpaper.user.$key"
    done
    original_uri="$(saved picture-uri)"
    original_path="$(python3 - "$original_uri" <<'PY'
import ast, pathlib, sys, urllib.parse
try:
    uri = ast.literal_eval(sys.argv[1])
    parsed = urllib.parse.urlparse(uri)
    print(urllib.parse.unquote(parsed.path) if parsed.scheme == 'file' else '')
except (SyntaxError, ValueError):
    print('')
PY
)"
    if [[ -n "$original_path" && -f "$original_path" ]]; then
      cp -p -- "$original_path" "$BACKUP_DIR/wallpaper.previous"
      printf '%s\n' "$original_path" > "$BACKUP_DIR/wallpaper.previous.path"
      hash_file "$original_path" > "$BACKUP_DIR/wallpaper.previous.sha256"
    fi
    printf 'Wallpaper backup saved. Current picture-uri: %s\n' "$original_uri"
    ;;
  apply)
    check_backup
    printf 'Planned GNOME changes:\n'
    for key in "${KEYS[@]}"; do
      printf '  %s: %s -> %s\n' "$key" "$(read_current "$key")" "$(expected_after "$key")"
    done
    printf 'Planned file: %s\n' "$INSTALLED_IMAGE"
    all_applied=true
    for key in "${KEYS[@]}"; do
      [[ "$(read_current "$key")" == "$(expected_after "$key")" ]] || all_applied=false
    done
    if [[ "$all_applied" == true ]]; then
      [[ -f "$INSTALLED_IMAGE" && "$(hash_file "$INSTALLED_IMAGE")" == "$expected_source_hash" ]] || {
        printf 'Configured wallpaper file is missing or changed.\n' >&2; exit 1;
      }
      printf 'Already up to date.\n'; exit 0
    fi
    for key in "${KEYS[@]}"; do
      [[ "$(read_current "$key")" == "$(saved "$key")" ]] || {
        printf 'Conflict: %s changed since wallpaper backup.\n' "$key" >&2; exit 1;
      }
    done
    check_original_image
    if [[ -e "$INSTALLED_IMAGE" && "$(hash_file "$INSTALLED_IMAGE")" != "$expected_source_hash" ]]; then
      printf 'Conflict: installed wallpaper path has different content.\n' >&2; exit 1
    fi
    if [[ "$DRY_RUN" == --dry-run ]]; then exit 0; fi
    umask 077
    if [[ ! -e "$INSTALLED_IMAGE" ]]; then
      mkdir -p -- "$(dirname -- "$INSTALLED_IMAGE")"
      cp -- "$SOURCE_IMAGE" "$INSTALLED_IMAGE"
      printf 'created\n' > "$BACKUP_DIR/wallpaper.asset-created"
    fi
    gsettings set "$SCHEMA" picture-options zoom
    gsettings set "$SCHEMA" picture-uri "$uri"
    gsettings set "$SCHEMA" picture-uri-dark "$uri"
    for key in "${KEYS[@]}"; do
      [[ "$(read_current "$key")" == "$(expected_after "$key")" ]] || {
        printf 'Failed to verify %s after applying wallpaper.\n' "$key" >&2; exit 1;
      }
      read_current "$key" > "$BACKUP_DIR/wallpaper.after.$key"
    done
    printf 'Wallpaper applied: %s\n' "$INSTALLED_IMAGE"
    ;;
  verify)
    check_backup
    for key in "${KEYS[@]}"; do
      [[ "$(read_current "$key")" == "$(expected_after "$key")" ]] || {
        printf 'Wallpaper setting differs: %s\n' "$key" >&2; exit 1;
      }
    done
    [[ -f "$INSTALLED_IMAGE" && "$(hash_file "$INSTALLED_IMAGE")" == "$expected_source_hash" ]] || {
      printf 'Wallpaper file is missing or changed.\n' >&2; exit 1;
    }
    printf 'Wallpaper settings and image checksum verified. Visual crop still needs review.\n'
    ;;
  rollback)
    check_backup
    all_original=true
    for key in "${KEYS[@]}"; do
      [[ "$(read_current "$key")" == "$(saved "$key")" ]] || all_original=false
    done
    if [[ "$all_original" == true ]]; then printf 'Wallpaper already rolled back.\n'; exit 0; fi
    check_original_image
    for key in "${KEYS[@]}"; do
      [[ -f "$BACKUP_DIR/wallpaper.after.$key" ]] || { printf 'No applied wallpaper record.\n' >&2; exit 1; }
      [[ "$(read_current "$key")" == "$(cat -- "$BACKUP_DIR/wallpaper.after.$key")" ]] || {
        printf 'Conflict: %s changed after apply.\n' "$key" >&2; exit 1;
      }
    done
    printf 'Will restore GNOME wallpaper values recorded in %s\n' "$BACKUP_DIR"
    for key in "${KEYS[@]}"; do printf '  %s -> %s\n' "$key" "$(saved "$key")"; done
    if [[ "$DRY_RUN" == --dry-run ]]; then exit 0; fi
    for key in "${KEYS[@]}"; do
      user_value="$(cat -- "$BACKUP_DIR/wallpaper.user.$key")"
      if [[ -n "$user_value" ]]; then
        gsettings set "$SCHEMA" "$key" "$user_value"
      else
        gsettings reset "$SCHEMA" "$key"
      fi
      [[ "$(read_current "$key")" == "$(saved "$key")" ]] || {
        printf 'Failed to restore %s.\n' "$key" >&2; exit 1;
      }
    done
    if [[ -f "$BACKUP_DIR/wallpaper.asset-created" && -f "$INSTALLED_IMAGE" ]]; then
      [[ "$(hash_file "$INSTALLED_IMAGE")" == "$expected_source_hash" ]] || {
        printf 'Wallpaper asset changed; leaving file in place.\n' >&2; exit 1;
      }
      rm -- "$INSTALLED_IMAGE"
    fi
    printf 'Wallpaper settings restored.\n'
    ;;
esac
