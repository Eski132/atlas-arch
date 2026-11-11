# atlas-arch

An Arch Linux compatibility wrapper for the Ruckus Cloudpath Wi-Fi installer.

Originally created for **Copernicus SG (Atlas College)** to connect Arch Linux devices to the school's secured Wi-Fi network.

It may also work with other schools and organizations using Debian&Fedora installer.

> [!NOTE]
> This project was made with the help of AI. It is not officially affiliated with Atlas College, Copernicus or Ruckus.

## Installation

1. Download your own Debian&Fedora installer (`Cloudpath-x64.tar.bz2`) schools website.

   https://eu5.cloudpath.net/enroll/Atlas-College/AtlasCollege/process

3. Run this command:
> [!NOTE]
> This will install that in Downloads file.
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Eski132/atlas-arch/main/install.sh) ~/Downloads/Cloudpath-x64.tar.bz2
```

3. Follow the Debian&Fedora installer instructions.

That's it!

## How It Works

Debian&Fedora installer doesn't officially support Arch Linux.

This wrapper temporarily makes Debian&Fedora installer detect Ubuntu 22.04 without modifying your actual operating system.

It installs the required dependencies and runs your own Debian&Fedora installer.

## Troubleshooting

If Cloudpath opens but displays `The session has been cancelled`, the GUI
message alone does not identify the cause. Reinstall the current wrapper and
retry with a freshly downloaded enrollment archive from the school portal.
The wrapper cannot renew or repair a cancelled server-side enrollment session.

Both installation methods now use the same launcher code, including Ubuntu
command detection and desktop-session forwarding. Unset desktop and locale
variables remain unset instead of being replaced with empty strings.

If the Cloudpath executable aborts with `std::out_of_range` or
`basic_string::substr`, the cause inside the proprietary executable remains
unconfirmed. The Arch wrapper now reports exit status 134 without masking it
with a Bash cleanup error.

To inspect the crash locally:

```bash
coredumpctl info Cloudpath-x64
```

Enrollment archives contain confidential tokens. Do not publish
`session.properties`, full core dumps, or unredacted enrollment logs.

## Requirements

- Arch Linux (x86_64)
- NetworkManager
- Temporary internet connection
- Your own Debian&Fedora installer (`Cloudpath-x64.tar.bz2`)

## Development checks

After editing a launcher, regenerate the standalone installer and package
checksums, then run the tests:

```bash
python3 tools/sync-installer.py
python3 -m unittest discover -s tests -v
```

Tests use a mock vendor executable and mock mount/privilege commands. They do
not validate real Cloudpath enrollment or modify the host network.

## Disclaimer

This project is experimental and has not undergone a security audit. Successful Wi-Fi enrollment is not guaranteed.

Created with AI assistance.

