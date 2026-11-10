pkgname=cloudpath-arch-wrapper
pkgver=0.2.0
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
  'networkmanager'
  'sed'
  'sudo'
  'systemd'
  'tar'
  'util-linux'
)
source=(
  'cloudpath-arch'
  'cloudpath-arch-ns'
  'cloudpath-arch-mount-run'
  'cloudpath-arch-lsb-release'
  'LICENSE'
)
sha256sums=(
  '2687af718755e9bef0c79776d5de4ae1e18f51d3cb1fd5351e60e4d3ccf5e5b8'
  '4c48c132aa7c9ed94233604512ccf0579a5c041c890687b366ed4466282a9c66'
  'f274ef166f69c3b0abb1d024ba3b87149a246f4f324eb475e48bd6a647581257'
  '15be76815dae642b3e4d15ada15ca95d8945f547d18debc9bc88f2600468bd74'
  'ba0abc0811f46d8a7ae3935dec98f5e26b52791f22397c8061f3049a227255ed'
)

package() {
  install -Dm755 "$srcdir/cloudpath-arch" "$pkgdir/usr/bin/cloudpath-arch"
  install -Dm755 "$srcdir/cloudpath-arch-ns" "$pkgdir/usr/lib/cloudpath-arch/cloudpath-arch-ns"
  install -Dm755 "$srcdir/cloudpath-arch-mount-run" "$pkgdir/usr/lib/cloudpath-arch/cloudpath-arch-mount-run"
  install -Dm755 "$srcdir/cloudpath-arch-lsb-release" "$pkgdir/usr/lib/cloudpath-arch/cloudpath-arch-lsb-release"
  install -Dm644 "$srcdir/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
