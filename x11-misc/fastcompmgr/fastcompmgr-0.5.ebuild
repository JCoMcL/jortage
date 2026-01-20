# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit virtualx

DESCRIPTION="A fast compositor for X11, a fork of an early version of Compton"
HOMEPAGE="https://github.com/tycho-kirchner/fastcompmgr"
SRC_URI="https://github.com/tycho-kirchner/fastcompmgr/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 ~arm64 ~ppc64 ~riscv x86"
IUSE=""

RDEPEND="
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXfixes
	x11-libs/libXrender
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
	dev-build/make
"

#PATCHES=(${FILESDIR}/${P}-add-destdir.patch)

src_compile() {
	emake
}

src_install() {
	emake install DESTDIR="${D}" PREFIX="/usr"
}
