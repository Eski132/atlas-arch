# atlas-arch

An Arch Linux compatibility wrapper for the Ruckus Cloudpath Wi-Fi installer.

Originally created for **Copernicus SG (Atlas College)**. It may also work with
other organizations that provide a Debian/Fedora Cloudpath installer.

> [!NOTE]
> This project is not officially affiliated with Atlas College, Copernicus, or Ruckus.

## Installation

Download your own `Cloudpath-x64.tar.bz2` enrollment archive from the
organization that issued it. Enrollment archives contain credentials and are
not interchangeable; do not ask someone else to share theirs.

Use a local clone so the installer and the deployed files come from the same
checkout:

```bash
git clone https://github.com/Eski132/atlas-arch.git
cd atlas-arch
bash ./install.sh
```

The installer installs the required packages and wrapper files. It does **not**
enable or start NetworkManager automatically. If NetworkManager is the network
manager you intend to use, start it explicitly when appropriate:

```bash
systemctl status NetworkManager
sudo systemctl start NetworkManager
```

Run the non-enrolling archive check first:

```bash
cloudpath-arch --check ~/Downloads/Cloudpath-x64.tar.bz2
```

If the check succeeds and NetworkManager is already active, launch enrollment:

```bash
cloudpath-arch ~/Downloads/Cloudpath-x64.tar.bz2
```

The installer preserves the vendor exit status. A failed optional enrollment
does not remove the installed wrapper, and the command prints the next useful
step.

## How it works

Cloudpath's Linux installer may check for Ubuntu/Fedora metadata even when it
uses NetworkManager for the actual connection. The wrapper:

1. validates and extracts the user's archive as the invoking user;
2. asks `sudo` to start a private **mount** namespace;
3. creates root-owned temporary Ubuntu 22.04 compatibility files and an
   `lsb_release` shim inside that namespace;
4. masks the relevant release files only in that namespace; and
5. drops privileges back to the invoking desktop user before starting the
   proprietary `Cloudpath-x64` executable.

The host's `/etc/lsb-release`, `/etc/os-release`, and `/usr/lib/os-release` are
not modified. The real NetworkManager, D-Bus, network, and user filesystem stay
visible to Cloudpath. A mount namespace is not a sandbox: do not run an
untrusted vendor binary, and do not assume it protects your files.

The child environment uses an explicit allowlist. Set variables remain set,
intentionally empty variables remain empty, and absent variables remain absent.
`HOME`, `USER`, `LOGNAME`, `SHELL`, and a trusted `PATH` are derived from the
invoking account after privilege drop. Sudo bookkeeping, loader variables, and
shell startup variables are not forwarded. The launcher puts the sudo,
namespace, and vendor chain in a separate process group so interruption can
terminate the group before private temporary data is cleaned up.

## Archive safety

Before extraction, the wrapper checks that the bzip2 tar archive can be listed
and rejects:

- malformed or truncated archives;
- absolute paths and `..` path components;
- symbolic links and hard links;
- device, FIFO, socket, and other special entries; and
- archives with zero or multiple valid Cloudpath payload directories.

The executable bit is repaired on the extracted `Cloudpath-x64` file when the
archive omitted it. Extraction is never performed as root. `session.properties`
and enrollment tokens are not printed by diagnostics.

## Troubleshooting

### `NetworkManager is not running`

The wrapper deliberately does not enable or start a network service. Check
which network manager owns the machine and start NetworkManager explicitly only
if that is what you intend to use.

### `archive does not contain one valid Cloudpath payload`

Use the original archive downloaded from the issuing organization. Do not
extract it manually as root. `cloudpath-arch --check` reports safe metadata
without printing token values.

### `Cloudpath aborted with exit status 134`

The wrapper preserves the vendor process status and reports that it terminated
abnormally. This does **not** prove the internal vendor crash's cause. An
empty environment is only a hypothesis, not a confirmed explanation.

For local investigation, use a redacted diagnostic such as:

```bash
coredumpctl info Cloudpath-x64
```

Do not share full enrollment archives, `session.properties`, tokens, complete
core dumps, or unredacted traces. Core dumps and traces may contain credentials.
The project does not promise secure erasure of temporary data after deletion.

### `must run as root through sudo` or namespace errors

The installed namespace helper is called by the wrapper through `sudo`; do not
add a passwordless sudo rule for it. Confirm that `util-linux`, `sudo`, and the
Arch `lsb-release` package are installed. The wrapper must be launched by a
normal desktop user, never by root.

## Requirements

- Arch Linux or an Arch-based system (x86_64)
- Bash, bzip2, coreutils, file, findutils, grep, sed, tar, util-linux, and sudo
- NetworkManager installed and explicitly started for enrollment
- The user's own `Cloudpath-x64.tar.bz2` archive
- A desktop session if the vendor installer needs GUI authentication

## Packaging

Build the package from the repository clone with an Arch packaging tool:

```bash
makepkg -sf
```

The PKGBUILD installs the same four runtime files used by the local installer
and includes the MIT license. Its checksums are generated from the checked-out
final files.

## Limitations

This wrapper has not been security-audited. It does not sandbox Cloudpath, does
not guarantee successful enrollment, and cannot diagnose proprietary vendor
internals without vendor symbols or a reproducible vendor-side failure.
