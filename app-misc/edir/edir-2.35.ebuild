# Maintainer: mark.blakeney at bullet-systems dot net
EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
DISTUTILS_USE_PEP517=setuptools
inherit pypi distutils-r1

DESCRIPTION="Program to rename, remove, and copy files and directories using your editor"
HOMEPAGE="https://github.com/bulletmark/edir"
SRC_URI="https://github.com/bulletmark/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3.0-or-later"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/argparse-from-file[${PYTHON_USEDEP}]
	dev-python/natsort[${PYTHON_USEDEP}]
"

BDEPEND="
	${PYTHON_DEPS}
"

src_prepare() {
	export SETUPTOOLS_SCM_PRETEND_VERSION=${PV}
	distutils-r1_src_prepare
}

