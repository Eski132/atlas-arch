#!/usr/bin/env bash
set -euo pipefail

PROGRAM='cloudpath-arch installer'
SCRIPT_DIR=$(cd -- "$(/usr/bin/dirname -- "${BASH_SOURCE[0]}")" && /usr/bin/pwd)
FILES=(
  cloudpath-arch
  cloudpath-arch-ns
  cloudpath-arch-mount-run
  cloudpath-arch-lsb-release
)

fail() {
  printf '%s: %s\n' "$PROGRAM" "$*" >&2
  exit 1
}

[[ -e /etc/arch-release ]] || fail 'this installer is for Arch Linux or an Arch-based system'
[[ $EUID -ne 0 ]] || fail 'run this installer as a normal user; it uses sudo only for package installation'

for file in "${FILES[@]}"; do
  [[ -f "$SCRIPT_DIR/$file" ]] || fail "missing $file; clone the repository and run install.sh from the clone"
done

[[ -x /usr/bin/sudo ]] || fail 'missing required command: /usr/bin/sudo'
[[ -x /usr/bin/pacman ]] || fail 'missing required command: /usr/bin/pacman'
[[ -x /usr/bin/install ]] || fail 'missing required command: /usr/bin/install'

printf 'Installing required packages. NetworkManager will not be enabled or started automatically.\n'
/usr/bin/sudo /usr/bin/pacman -S --needed bzip2 file lsb-release networkmanager sudo util-linux

/usr/bin/sudo /usr/bin/install -Dm755 "$SCRIPT_DIR/cloudpath-arch" /usr/bin/cloudpath-arch
/usr/bin/sudo /usr/bin/install -Dm755 "$SCRIPT_DIR/cloudpath-arch-ns" /usr/lib/cloudpath-arch/cloudpath-arch-ns
/usr/bin/sudo /usr/bin/install -Dm755 "$SCRIPT_DIR/cloudpath-arch-mount-run" /usr/lib/cloudpath-arch/cloudpath-arch-mount-run
/usr/bin/sudo /usr/bin/install -Dm755 "$SCRIPT_DIR/cloudpath-arch-lsb-release" /usr/lib/cloudpath-arch/cloudpath-arch-lsb-release

printf 'Installed cloudpath-arch.\n'
printf 'Before enrollment, explicitly start NetworkManager if it is not already active.\n'
printf 'Run: systemctl status NetworkManager\n'
printf 'Then: cloudpath-arch --check /path/to/Cloudpath-x64.tar.bz2\n'

if (( $# > 0 )); then
  if /usr/bin/cloudpath-arch "$@"; then
    exit 0
  else
    status=$?
    printf '%s: optional enrollment failed with exit status %d; the wrapper is installed.\n' "$PROGRAM" "$status" >&2
    exit "$status"
  fi
fi
