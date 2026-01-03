# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/tlsa/libcyaml.git"
else
	SRC_URI="https://github.com/tlsa/libcyaml/archive/v${PV}.tar.gz  -> ${P}.tar.gz"
	KEYWORDS="~amd64"
fi

DESCRIPTION="C library for reading and writing YAML"
HOMEPAGE="https://github.com/tlsa/libcyaml/"
LICENSE="ISC"
SLOT="0"

src_compile() {
	emake VARIANT=release
}

src_install() {
	emake DESTDIR="${D}" PREFIX="/usr" LIBDIR="$(get_libdir)" VARIANT=release install
}
