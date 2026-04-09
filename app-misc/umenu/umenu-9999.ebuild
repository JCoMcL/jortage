# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A simple menu utility for the shell"
HOMEPAGE="https://github.com/jcomcl/umenu"
SRC_URI="https://github.com/jcomcl/umenu/archive/master.zip -> ${P}.zip"

LICENSE="Unlicense"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}/${PN}-master"

src_compile() {
	emake
}

src_install() {
	dobin umenu
	doman umenu.1
}
