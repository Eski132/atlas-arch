pkgname=cloudpath-arch-wrapper
pkgver=0.1.0
pkgrel=3
pkgdesc='Run user-provided Cloudpath XpressConnect Linux installers on Arch Linux'
arch=('x86_64')
url='https://github.com/Eski132/atlas-arch'
license=('MIT')
depends=(
  'bash'
  'bzip2'
  'coreutils'
  'file'
  'findutils'
  'grep'
  'lsb-release'
  'lshw'
  'networkmanager'
  'sed'
  'sudo'
  'tar'
  'util-linux'
  'wireless_tools'
)
source=(
  'cloudpath-arch'
  'cloudpath-arch-ns'
  'cloudpath-arch-mount-run'
)
sha256sums=(
  'ed718ea988d30aa9ddd4cb3537f2d61adb75ca1235c5324574e86b3180228e51'
  'f14f990eaa06e8fbd7dfe4ad2a9b65bd5531e7dd99eba3dbe8f5e4dda5b7604b'
  '976d9e21bf0f3b69357abff8d90839164fad8e8c033bc536f401c816ec6a7cf6'
)

package() {
  install -Dm755 "$srcdir/cloudpath-arch" "$pkgdir/usr/bin/cloudpath-arch"
  install -Dm755 "$srcdir/cloudpath-arch-ns" "$pkgdir/usr/lib/cloudpath-arch/cloudpath-arch-ns"
  install -Dm755 "$srcdir/cloudpath-arch-mount-run" "$pkgdir/usr/lib/cloudpath-arch/cloudpath-arch-mount-run"
}

