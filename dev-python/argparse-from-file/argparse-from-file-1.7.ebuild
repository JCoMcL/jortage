EAPI=8

PYTHON_COMPAT=( python3_{10..12} )
DISTUTILS_USE_PEP517=setuptools
inherit pypi distutils-r1

DESCRIPTION="Wrapper for Python's argparse to also read arguments from a file"
HOMEPAGE="https://github.com/bulletmark/argparse-from-file"
SRC_URI="https://github.com/bulletmark/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3.0-or-later"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-python/platformdirs[${PYTHON_USEDEP}]
"
BDEPEND="
	${PYTHON_DEPS}
"

src_unpack() {
	default
	mv "$WORKDIR/argparse-from-file-${PV}" "${S}"
}

src_prepare() {
	export SETUPTOOLS_SCM_PRETEND_VERSION=${PV}
	distutils-r1_src_prepare
}
