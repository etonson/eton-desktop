#!/usr/bin/env bash
# Install user-scoped assets, then apply the versioned GNOME profile.
set -euo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

case "${1:-}" in
  '') ;;
  --check) exec /usr/bin/python3 "$PROJECT_DIR/scripts/settings.py" check ;;
  -h|--help)
    echo 'Usage: ./scripts/install.sh [--check]'
    echo 'Run from a GNOME desktop terminal as your regular user, without sudo.'
    exit 0 ;;
  *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

/usr/bin/python3 "$PROJECT_DIR/scripts/settings.py" check
read_source() {
  /usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]][sys.argv[3]])' \
    "$PROJECT_DIR/config/sources.json" "$1" "$2"
}
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/eton-desktop.XXXXXXXX")"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

echo 'Downloading the pinned Tela source...'
git clone --quiet --no-checkout "$(read_source tela repository)" "$TEMP_DIR/Tela"
git -C "$TEMP_DIR/Tela" checkout --quiet --detach "$(read_source tela commit)"
(cd "$TEMP_DIR/Tela" && ./install.sh -d "$DATA_DIR/icons")

echo 'Downloading and verifying Blur my Shell...'
curl --fail --location --silent --show-error --retry 3 \
  "$(read_source blur_my_shell url)" -o "$TEMP_DIR/blur-my-shell.zip"
printf '%s  %s\n' "$(read_source blur_my_shell sha256)" "$TEMP_DIR/blur-my-shell.zip" | sha256sum --check --status
/usr/bin/python3 - "$TEMP_DIR/blur-my-shell.zip" "$PROJECT_DIR/config/sources.json" <<'PY'
import json, sys, zipfile
expected = json.load(open(sys.argv[2]))['blur_my_shell']
with zipfile.ZipFile(sys.argv[1]) as archive:
    metadata = json.loads(archive.read('metadata.json'))
if metadata['uuid'] != expected['uuid'] or metadata['version'] != expected['version']:
    raise SystemExit('Extension metadata does not match config/sources.json')
PY
gnome-extensions install --force "$TEMP_DIR/blur-my-shell.zip"
echo 'Applying the profile...'
/usr/bin/python3 "$PROJECT_DIR/scripts/settings.py" apply
