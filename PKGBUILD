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
  '50dc334d488a1c84f30ecf090ca014984970df1e388d8a45146dab345d463464'
  'b0064fe2bedf8a6dbe1d8c5b3f2fc984232e19fe90cec9287ea3d4aeaf0adee5'
  '3be25be3f4ce6dc0fa8cdaf1528d8c472b05763e8cce4baffcbc5740bd2235ec'
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
