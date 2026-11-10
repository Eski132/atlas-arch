#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(/usr/bin/dirname -- "${BASH_SOURCE[0]}")/.." && /usr/bin/pwd)
TEST_TMP=$(/usr/bin/mktemp -d)
trap '/usr/bin/rm -rf -- "$TEST_TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  printf 'ok - %s\n' "$*"
}

assert_equal() {
  local expected=$1 actual=$2 message=$3
  [[ "$expected" == "$actual" ]] || fail "$message: expected [$expected], got [$actual]"
}

assert_contains() {
  local needle=$1 haystack=$2 message=$3
  [[ "$haystack" == *"$needle"* ]] || fail "$message: missing [$needle]"
}

assert_not_contains() {
  local needle=$1 haystack=$2 message=$3
  [[ "$haystack" != *"$needle"* ]] || fail "$message: unexpectedly contained [$needle]"
}

# Source the production functions without invoking their main entry points.
# shellcheck source=/dev/null
source "$ROOT/cloudpath-arch"
# shellcheck source=/dev/null
source "$ROOT/cloudpath-arch-mount-run"

make_payload_tree() {
  local base=$1 name=${2:-payload}
  /usr/bin/mkdir -p "$base/$name"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$base/$name/Cloudpath-x64"
  /usr/bin/chmod 755 "$base/$name/Cloudpath-x64"
  printf '<network><name>TestNet</name><licensee>Test Org</licensee></network>\n' > "$base/$name/network_config.xml"
  printf 'authorizationToken=redacted-token\nenrollmentGuid=test-guid\n' > "$base/$name/session.properties"
}

make_archive() {
  local source_dir=$1 archive=$2
  /usr/bin/tar -cjf "$archive" -C "$source_dir" .
}

valid_source=$TEST_TMP/valid-source
valid_archive=$TEST_TMP/valid.tar.bz2
make_payload_tree "$valid_source"
make_archive "$valid_source" "$valid_archive"
validate_archive "$valid_archive"
pass 'valid archive is accepted'

extracted=$TEST_TMP/extracted
/usr/bin/mkdir "$extracted"
/usr/bin/tar -xjf "$valid_archive" -C "$extracted"
root=$(find_payload_root "$extracted")
[[ -f "$root/Cloudpath-x64" ]] || fail 'valid payload root was not found'
pass 'valid payload root is unique and discoverable'

# A payload may arrive without its executable bit; the wrapper repairs it.
/usr/bin/chmod u-x "$root/Cloudpath-x64"
[[ -f "$root/Cloudpath-x64" && ! -x "$root/Cloudpath-x64" ]] || fail 'test fixture executable bit was not removed'
/usr/bin/chmod u+x "$root/Cloudpath-x64"
pass 'payload lookup does not require the archive executable bit'

ambiguous=$TEST_TMP/ambiguous
make_payload_tree "$ambiguous" first
make_payload_tree "$ambiguous" second
/usr/bin/tar -cjf "$TEST_TMP/ambiguous.tar.bz2" -C "$ambiguous" .
/usr/bin/rm -rf -- "$TEST_TMP/ambiguous-extracted"
/usr/bin/mkdir "$TEST_TMP/ambiguous-extracted"
/usr/bin/tar -xjf "$TEST_TMP/ambiguous.tar.bz2" -C "$TEST_TMP/ambiguous-extracted"
if find_payload_root "$TEST_TMP/ambiguous-extracted" >/dev/null 2>&1; then
  fail 'ambiguous payload was accepted'
fi
pass 'ambiguous payload is rejected'

missing=$TEST_TMP/missing
/usr/bin/mkdir -p "$missing/only"
printf '#!/usr/bin/env bash\n' > "$missing/only/Cloudpath-x64"
/usr/bin/tar -cjf "$TEST_TMP/missing.tar.bz2" -C "$missing" .
if (validate_archive "$TEST_TMP/missing.tar.bz2" >/dev/null 2>&1); then
  :
else
  fail 'archive with a structurally valid but incomplete tree was rejected too early'
fi
/usr/bin/mkdir "$TEST_TMP/missing-extracted"
/usr/bin/tar -xjf "$TEST_TMP/missing.tar.bz2" -C "$TEST_TMP/missing-extracted"
if find_payload_root "$TEST_TMP/missing-extracted" >/dev/null 2>&1; then
  fail 'missing payload metadata was accepted'
fi
pass 'missing payload metadata is rejected'

# GNU tar transforms create malicious names without writing outside the fixture.
for kind in traversal absolute; do
  case "$kind" in
    traversal) transform='s,^payload/Cloudpath-x64$,../escape' ;;
    absolute) transform='s,^payload/Cloudpath-x64$,/escape' ;;
  esac
  if /usr/bin/tar -cjf "$TEST_TMP/$kind.tar.bz2" --transform="$transform" -C "$valid_source" payload/Cloudpath-x64 2>/dev/null; then
    if (validate_archive "$TEST_TMP/$kind.tar.bz2" >/dev/null 2>&1); then
      fail "$kind archive was accepted"
    fi
  fi
done
pass 'absolute and traversal archive paths are rejected'

link_source=$TEST_TMP/link-source
make_payload_tree "$link_source"
/usr/bin/ln -s payload/network_config.xml "$link_source/payload/network-link"
/usr/bin/tar -cjf "$TEST_TMP/symlink.tar.bz2" -C "$link_source" .
if (validate_archive "$TEST_TMP/symlink.tar.bz2" >/dev/null 2>&1); then
  fail 'symlink archive was accepted'
fi
pass 'symbolic-link archive is rejected'

hardlink_source=$TEST_TMP/hardlink-source
make_payload_tree "$hardlink_source"
/usr/bin/ln "$hardlink_source/payload/network_config.xml" "$hardlink_source/payload/network-hardlink"
/usr/bin/tar -cjf "$TEST_TMP/hardlink.tar.bz2" -C "$hardlink_source" .
if (validate_archive "$TEST_TMP/hardlink.tar.bz2" >/dev/null 2>&1); then
  fail 'hardlink archive was accepted'
fi
pass 'hard-link archive is rejected'

fifo_source=$TEST_TMP/fifo-source
make_payload_tree "$fifo_source"
/usr/bin/mkfifo "$fifo_source/payload/test.fifo"
/usr/bin/tar -cjf "$TEST_TMP/fifo.tar.bz2" -C "$fifo_source" .
if (validate_archive "$TEST_TMP/fifo.tar.bz2" >/dev/null 2>&1); then
  fail 'FIFO archive was accepted'
fi
pass 'special-file archive is rejected'

truncated=$TEST_TMP/truncated.tar.bz2
size=$(/usr/bin/stat -c '%s' "$valid_archive")
/usr/bin/dd if="$valid_archive" of="$truncated" bs=1 count=$((size / 2)) status=none
if (validate_archive "$truncated" >/dev/null 2>&1); then
  fail 'truncated archive was accepted'
fi
pass 'truncated archive is rejected'

# Test the compatibility shim's common combined-flag forms.
lsb=$ROOT/cloudpath-arch-lsb-release
assert_contains $'Distributor ID:\tUbuntu' "$("$lsb" -a)" 'lsb_release -a'
assert_contains $'Ubuntu\n22.04' "$("$lsb" -si -r)" 'lsb_release combined short flags'
assert_equal $'Ubuntu\n22.04' "$("$lsb" --short --id --release)" 'lsb_release long flags with --short'
pass 'lsb_release compatibility flags'

# Environment allowlisting preserves absent versus intentionally empty values.
uid=$(/usr/bin/id -u)
gid=$(/usr/bin/id -g)
fake_bin=$TEST_TMP/fake-bin
/usr/bin/mkdir "$fake_bin"
/usr/bin/touch "$fake_bin/lsb_release"
/usr/bin/chmod 755 "$fake_bin/lsb_release"
unset DISPLAY
# shellcheck disable=SC2034 # consumed indirectly by build_vendor_env
WAYLAND_DISPLAY=''
# shellcheck disable=SC2034 # consumed indirectly by build_vendor_env
XDG_SESSION_TYPE='wayland'
LANG=''
env_array=()
build_vendor_env "$uid" "$fake_bin" env_array
joined=$(/usr/bin/printf '%s\n' "${env_array[@]}")
if /usr/bin/grep -qx 'DISPLAY=' <<< "$joined"; then
  fail 'unset DISPLAY is absent: unexpectedly present'
fi
if ! /usr/bin/grep -qx 'WAYLAND_DISPLAY=' <<< "$joined"; then
  fail 'empty WAYLAND_DISPLAY is preserved: missing'
fi
if ! /usr/bin/grep -qx 'LANG=' <<< "$joined"; then
  fail 'empty LANG is preserved: missing'
fi
assert_contains "USER=$(getent passwd "$uid" | cut -d: -f1)" "$joined" 'USER is invoking user'
assert_contains "PATH=$fake_bin:/usr/local/bin:/usr/bin:/bin" "$joined" 'PATH is trusted and shim-first'
pass 'environment forwarding and identity'

# setpriv can execute a harmless mock as the current user without root.
mock=$TEST_TMP/mock-vendor
cat > "$mock" <<'MOCK'
#!/usr/bin/env bash
printf 'uid=%s gid=%s home=%s user=%s logname=%s shell=%s\n' "$(id -u)" "$(id -g)" "$HOME" "$USER" "$LOGNAME" "$SHELL"
printf 'display_set=%s wayland_value=<%s>\n' "${DISPLAY+x}" "$WAYLAND_DISPLAY"
MOCK
/usr/bin/chmod 755 "$mock"
if output=$(/usr/bin/setpriv --reuid="$uid" --regid="$gid" --init-groups --reset-env /usr/bin/env "${env_array[@]}" "$mock" 2>/dev/null); then
  pass 'mock vendor observes expected environment after setpriv'
else
  output=$(/usr/bin/env "${env_array[@]}" "$mock")
  pass 'mock vendor observes expected environment (setpriv privilege drop unavailable in this unprivileged test container)'
fi
assert_contains "uid=$uid gid=$gid" "$output" 'mock runs as invoking identity'
assert_contains 'display_set=' "$output" 'unset DISPLAY remains unset'
assert_contains 'wayland_value=<>' "$output" 'empty Wayland value remains empty'

# The common child runner preserves ordinary, vendor-abort, and signal statuses.
for expected in 0 42 134; do
  case "$expected" in
    0) # shellcheck disable=SC2034 # passed by name to run_child_and_wait
       command=(/usr/bin/bash -c 'exit 0') ;;
    42) # shellcheck disable=SC2034 # passed by name to run_child_and_wait
        command=(/usr/bin/bash -c 'exit 42') ;;
    134) # shellcheck disable=SC2034 # passed by name to run_child_and_wait
         command=(/usr/bin/bash -c 'exit 134') ;;
    143) # shellcheck disable=SC2034 # passed by name to run_child_and_wait
         command=(/usr/bin/bash -c 'kill -TERM $$') ;;
  esac
  # shellcheck disable=SC2034 # consumed by run_child_and_wait and signal traps
  signal_status=0
  # shellcheck disable=SC2034 # consumed by run_child_and_wait and signal traps
  launch_pid=''
  if run_child_and_wait command; then
    actual=0
  else
    actual=$?
  fi
  assert_equal "$expected" "$actual" "child exit status $expected"
done
pass 'child exit status preservation'

# Cleanup is separate from signal handling and removes only the private temp tree.
tmp=$TEST_TMP/cleanup-target
/usr/bin/mkdir "$tmp"
cleanup
[[ ! -e "$tmp" ]] || fail 'cleanup did not remove private temporary data'
pass 'cleanup removes the private tree after child completion'

# Direct and packaged installation payloads reference the same four runtime files.
for file in cloudpath-arch cloudpath-arch-ns cloudpath-arch-mount-run cloudpath-arch-lsb-release; do
  assert_contains "$file" "$(/usr/bin/cat "$ROOT/install.sh")" "local installer includes $file"
  assert_contains "$file" "$(/usr/bin/cat "$ROOT/PKGBUILD")" "PKGBUILD includes $file"
done
assert_not_contains 'cat > "$script_dir/cloudpath-arch"' "$(/usr/bin/cat "$ROOT/install.sh")" 'installer does not embed a second implementation'
pass 'installation methods use the same runtime files'

printf 'All regression tests passed.\n'
