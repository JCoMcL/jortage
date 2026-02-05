# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{9..14} )
inherit distutils-r1

DESCRIPTION="A command line interface for The Pirate Bay"
HOMEPAGE="https://github.com/vikstrous/pirate-get"
SRC_URI="https://github.com/vikstrous/pirate-get/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="AGPL-3.0-or-later"
SLOT="0"
KEYWORDS="~amd64"

IUSE="test"

DISTUTILS_PN_SUBDIR_EXCLUDE="tests"
RDEPEND="
	>=dev-python/colorama-0.3.3
	>=dev-python/pyperclip-1.6.2
	dev-python/packaging
"
DEPEND="${RDEPEND}"
BDEPEND="
	test? ( dev-python/pytest )
	test? ( dev-python/coverage )
	test? ( dev-python/coveralls )
"

PATCHES=(
	${FILESDIR}/${P}-no-veryprettytable.patch
	${FILESDIR}/pyproject.patch
)

distutils_enable_tests pytest





