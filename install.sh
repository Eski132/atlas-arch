#!/usr/bin/env bash
set -euo pipefail

if [[ ! -e /etc/arch-release ]]; then
  printf 'This installer is for Arch Linux / Arch-based systems.\n' >&2
  exit 1
fi

for cmd in sudo pacman install mktemp; do
  command -v "$cmd" >/dev/null 2>&1 || { printf 'Missing required command: %s\n' "$cmd" >&2; exit 1; }
done

script_dir=$(mktemp -d)
trap 'rm -rf -- "$script_dir"' EXIT HUP INT TERM

cat > "$script_dir/cloudpath-arch" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

PROGRAM='cloudpath-arch'
RUNTIME_HELPER='/usr/lib/cloudpath-arch/cloudpath-arch-ns'

usage() {
  cat <<'USAGE'
Usage:
  cloudpath-arch /path/to/Cloudpath-x64.tar.bz2
  cloudpath-arch --check /path/to/Cloudpath-x64.tar.bz2
USAGE
}

die() { printf '%s: %s\n' "$PROGRAM" "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

check_archive_paths() {
  local archive=$1 entry
  while IFS= read -r entry; do
    case "$entry" in /*|../*|*/../*|*/..) die "archive contains an unsafe path: $entry" ;; esac
  done < <(tar -tjf "$archive")
}

find_payload_root() {
  local dir=$1 candidate
  if [[ -x "$dir/Cloudpath-x64" && -f "$dir/network_config.xml" && -f "$dir/session.properties" ]]; then
    printf '%s\n' "$dir"; return 0
  fi
  candidate=$(find "$dir" -mindepth 1 -maxdepth 3 -type f -name Cloudpath-x64 -print -quit)
  [[ -n "$candidate" ]] || return 1
  candidate=${candidate%/Cloudpath-x64}
  [[ -f "$candidate/network_config.xml" && -f "$candidate/session.properties" ]] || return 1
  printf '%s\n' "$candidate"
}

show_check() {
  local root=$1 network='unknown' licensee='unknown'
  network=$(sed -n 's:.*<name>\([^<]*\)</name>.*:\1:p' "$root/network_config.xml" | head -n1 || true)
  licensee=$(sed -n 's:.*<licensee>\([^<]*\)</licensee>.*:\1:p' "$root/network_config.xml" | head -n1 || true)
  printf 'Archive looks usable.\n  Network: %s\n  Licensee: %s\n  Executable: %s\n' "$network" "$licensee" "$(file -b "$root/Cloudpath-x64")"
  grep -q '^authorizationToken=' "$root/session.properties" && printf '  Enrollment token: present (value intentionally not displayed)\n' || printf '  Enrollment token: not found\n'
  grep -q '^enrollmentGuid=' "$root/session.properties" && printf '  Enrollment GUID: present (value intentionally not displayed)\n' || printf '  Enrollment GUID: not found\n'
}

main() {
  local check_only=0 archive tmp payload_root runtime_base
  if [[ ${1:-} == '--check' ]]; then check_only=1; shift; fi
  [[ $# -eq 1 ]] || { usage >&2; exit 2; }
  archive=$1
  [[ -f "$archive" ]] || die "archive not found: $archive"
  [[ -r "$archive" ]] || die "archive is not readable: $archive"
  [[ $(uname -m) == x86_64 ]] || die 'this wrapper currently supports x86_64 Cloudpath installers only'
  [[ -e /etc/arch-release ]] || die 'this package is intended for Arch Linux and Arch-based systems'
  need tar; need find; need sed; need grep; need file
  check_archive_paths "$archive"

  umask 077
  runtime_base=${XDG_RUNTIME_DIR:-/tmp}
  [[ -d "$runtime_base" && -w "$runtime_base" ]] || runtime_base=/tmp
  tmp=$(mktemp -d "$runtime_base/cloudpath-arch.XXXXXXXX")
  trap 'rm -rf -- "$tmp"' EXIT HUP INT TERM
  mkdir -p "$tmp/payload" "$tmp/fake-release"
  tar -xjf "$archive" -C "$tmp/payload" --no-same-owner --no-same-permissions
  payload_root=$(find_payload_root "$tmp/payload") || die 'archive does not contain the expected Cloudpath-x64 payload'
  chmod u+x "$payload_root/Cloudpath-x64"

  if (( check_only )); then show_check "$payload_root"; exit 0; fi
  [[ -x "$RUNTIME_HELPER" ]] || die "runtime helper missing: $RUNTIME_HELPER"
  need sudo; need systemctl
  systemctl -q is-active NetworkManager.service || die 'NetworkManager is not running (enable/start NetworkManager first)'

  cat > "$tmp/fake-release/lsb-release" <<'RELEASE'
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=22.04
DISTRIB_CODENAME=jammy
DISTRIB_DESCRIPTION="Ubuntu 22.04 LTS"
RELEASE
  cat > "$tmp/fake-release/os-release" <<'RELEASE'
NAME="Ubuntu"
VERSION="22.04 LTS (Jammy Jellyfish)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 22.04 LTS"
VERSION_ID="22.04"
VERSION_CODENAME=jammy
UBUNTU_CODENAME=jammy
RELEASE

  printf 'Starting Cloudpath with temporary Ubuntu compatibility metadata.\n'
  sudo env "HOME=$HOME" "USER=${USER:-$(id -un)}" "LOGNAME=${LOGNAME:-${USER:-$(id -un)}}" "PATH=$PATH" \
    "DISPLAY=${DISPLAY:-}" "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}" "XAUTHORITY=${XAUTHORITY:-}" \
    "DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-}" "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-}" \
    "$RUNTIME_HELPER" "$(id -u)" "$(id -g)" "$payload_root" "$tmp/fake-release"
}
main "$@"
SCRIPT

cat > "$script_dir/cloudpath-arch-ns" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { printf 'cloudpath-arch-ns: must run as root\n' >&2; exit 1; }
[[ $# -eq 4 ]] || { printf 'cloudpath-arch-ns: invalid arguments\n' >&2; exit 2; }
uid=$1; gid=$2; payload_root=$3; fake_release=$4
[[ "$uid" =~ ^[0-9]+$ && "$gid" =~ ^[0-9]+$ ]] || { printf 'cloudpath-arch-ns: invalid uid/gid\n' >&2; exit 2; }
[[ -x "$payload_root/Cloudpath-x64" ]] || { printf 'cloudpath-arch-ns: Cloudpath executable missing\n' >&2; exit 1; }
[[ -f "$fake_release/lsb-release" && -f "$fake_release/os-release" ]] || { printf 'cloudpath-arch-ns: compatibility metadata missing\n' >&2; exit 1; }
[[ -e /etc/lsb-release ]] || { printf 'cloudpath-arch-ns: /etc/lsb-release missing; install lsb-release\n' >&2; exit 1; }
[[ -e /usr/lib/os-release ]] || { printf 'cloudpath-arch-ns: /usr/lib/os-release missing\n' >&2; exit 1; }
unshare --mount --fork --propagation private -- /usr/lib/cloudpath-arch/cloudpath-arch-mount-run "$uid" "$gid" "$payload_root" "$fake_release"
SCRIPT

cat > "$script_dir/cloudpath-arch-mount-run" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail
uid=$1; gid=$2; payload_root=$3; fake_release=$4
mount --bind "$fake_release/lsb-release" /etc/lsb-release
mount -o remount,bind,ro /etc/lsb-release
mount --bind "$fake_release/os-release" /usr/lib/os-release
mount -o remount,bind,ro /usr/lib/os-release
if [[ -e /etc/os-release && ! -L /etc/os-release ]]; then
  mount --bind "$fake_release/os-release" /etc/os-release
  mount -o remount,bind,ro /etc/os-release
fi
cd "$payload_root"
exec setpriv --reuid="$uid" --regid="$gid" --init-groups --reset-env env \
  "HOME=${HOME:-/tmp}" "USER=${USER:-}" "LOGNAME=${LOGNAME:-}" "PATH=${PATH:-/usr/local/sbin:/usr/local/bin:/usr/bin}" \
  "DISPLAY=${DISPLAY:-}" "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}" "XAUTHORITY=${XAUTHORITY:-}" \
  "DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-}" "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-}" ./Cloudpath-x64
SCRIPT

printf 'Installing dependencies...\n'
sudo pacman -S --needed --noconfirm bzip2 file lsb-release lshw networkmanager sudo util-linux wireless_tools

sudo install -Dm755 "$script_dir/cloudpath-arch" /usr/bin/cloudpath-arch
sudo install -Dm755 "$script_dir/cloudpath-arch-ns" /usr/lib/cloudpath-arch/cloudpath-arch-ns
sudo install -Dm755 "$script_dir/cloudpath-arch-mount-run" /usr/lib/cloudpath-arch/cloudpath-arch-mount-run
sudo systemctl enable --now NetworkManager.service

printf 'cloudpath-arch installed.\n'
if [[ $# -gt 0 ]]; then
  exec cloudpath-arch "$@"
fi
printf 'Run: cloudpath-arch ~/Downloads/Cloudpath-x64.tar.bz2\n'
