pkgname=cloudpath-arch-wrapper
pkgver=0.1.0
pkgrel=1
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
  'bd0566a9e337d68ede718a17fad062116db260612fea95c29351e1e9cc3e499d'
  '08aca6f4002b05ce70d248a45d960832acd0c4ab1006b9a7ff553a22243aa508'
  '466c9ac9837e5fcf423bcd2395e991750f462dbb7bdd4a3b11ca062dd5877bf5'
)

package() {
  install -Dm755 "$srcdir/cloudpath-arch" "$pkgdir/usr/bin/cloudpath-arch"
  install -Dm755 "$srcdir/cloudpath-arch-ns" "$pkgdir/usr/lib/cloudpath-arch/cloudpath-arch-ns"
  install -Dm755 "$srcdir/cloudpath-arch-mount-run" "$pkgdir/usr/lib/cloudpath-arch/cloudpath-arch-mount-run"
}
