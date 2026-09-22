# cloudpath-arch-wrapper

A small Arch Linux compatibility wrapper for **user-provided** Ruckus/Cloudpath XpressConnect Linux installers.

It does **not** redistribute Cloudpath, a school/company configuration, enrollment tokens, certificates, usernames, or any other enrollment material.

## Why this exists

Some Cloudpath deployments ship a Linux executable whose network configuration is implemented through NetworkManager, but whose profile selection only allows Ubuntu/Fedora. On Arch this can result in an "operating system not supported" message.

This wrapper runs the user's own downloaded Cloudpath archive while presenting Ubuntu 22.04 distro metadata **inside a temporary mount namespace**. It does not rewrite `/etc/os-release`, `/usr/lib/os-release`, or `/etc/lsb-release` on the host.

## One-command install + run

After downloading your own Cloudpath archive from your organization, run:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/cloudpath-arch-wrapper/main/install.sh) ~/Downloads/Cloudpath-x64.tar.bz2
```

Replace `YOUR_USERNAME` with the GitHub account that publishes this repository. The installer contains no Cloudpath enrollment data; the `.tar.bz2` stays local to the machine running it.

## Install from a clone

```bash
makepkg -si
```

## Use

Download a fresh Linux x64 Cloudpath installer from your organization's onboarding portal, then run:

```bash
cloudpath-arch ~/Downloads/Cloudpath-x64.tar.bz2
```

To validate an archive without launching Cloudpath:

```bash
cloudpath-arch --check ~/Downloads/Cloudpath-x64.tar.bz2
```

## Privacy / publishing

Cloudpath archives can contain short-lived or account/session-specific enrollment material such as:

- `authorizationToken`
- `enrollmentGuid`
- organization-specific certificate authorities and URLs

Do not commit a downloaded `Cloudpath-*.tar.bz2`, extracted `session.properties`, or generated client certificates to a public repository.

The wrapper extracts a user's archive into a mode-0700 temporary directory and removes it when the wrapper exits normally or receives HUP/INT/TERM. The token is never printed by `--check`.

## How it works

1. Validates that the supplied archive has safe relative paths.
2. Extracts it to a private temporary directory.
3. Confirms the expected Cloudpath executable/config files exist.
4. Starts a root-created **mount namespace only** using `unshare`.
5. Bind-mounts temporary Ubuntu 22.04 `lsb-release`/`os-release` files over the distro-identification files inside that namespace.
6. Drops back to the invoking user and launches `Cloudpath-x64`.
7. Cloudpath still talks to the real host NetworkManager/D-Bus and can use the normal privilege mechanisms when required.
8. The temporary payload is removed after Cloudpath exits.

No Cloudpath configuration file is modified, which avoids breaking vendor configuration integrity/checksum mechanisms.

## Requirements

The PKGBUILD installs/declares the Arch packages used by the wrapper and by older Cloudpath Linux clients, including NetworkManager, `lsb-release`, `lshw`, and the legacy `wireless_tools` utilities.

NetworkManager must be running.

## Scope

This is a compatibility wrapper, not a reimplementation of Cloudpath's enrollment protocol. Each user must obtain their own legitimate installer/enrollment session from the organization that operates the network.

## License

The wrapper code in this repository is MIT licensed. Ruckus/Cloudpath itself is not included and is governed by its own terms.
