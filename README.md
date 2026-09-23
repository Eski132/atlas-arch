# atlas-arch

An Arch Linux compatibility wrapper for the Ruckus Cloudpath Wi-Fi installer.

Originally created for **Copernicus SG (Atlas College)** to connect Arch Linux devices to the school's secured Wi-Fi network.

It may also work with other schools and organizations using Cloudpath.

> [!NOTE]
> This project was made with the help of AI. It is not officially affiliated with Atlas College, Copernicus or Ruckus.

## Installation

1. Download your own `Cloudpath-x64.tar.bz2` installer from your school or organization.

2. Run this command:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Eski132/atlas-arch/main/install.sh) ~/Downloads/Cloudpath-x64.tar.bz2
```

3. Follow the Cloudpath installer instructions.

That's it!

## How It Works

Cloudpath doesn't officially support Arch Linux.

This wrapper temporarily makes Cloudpath detect Ubuntu 22.04 without modifying your actual operating system.

It installs the required dependencies and runs your own Cloudpath installer.

## Requirements

- Arch Linux (x86_64)
- NetworkManager
- Internet connection
- Your own Cloudpath installer

## Privacy

This repository does not contain or distribute personal certificates, school credentials or enrollment tokens.

Every user must download their own Cloudpath installer.

Never upload your certificates or enrollment files to GitHub.

## Disclaimer

This project is experimental and has not undergone a security audit. Successful Wi-Fi enrollment is not guaranteed.

Created with AI assistance.

## License

MIT License.
