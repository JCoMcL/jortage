# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson xdg

DESCRIPTION="A feature-rich digital audio workstation with support for various plugin formats"
HOMEPAGE="https://www.zrythm.org/"
SRC_URI="https://github.com/zrythm/zrythm/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="AGPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="debug"

RESTRICT="mirror"

# NOTE:
# Upstream uses Meson wrap heavily.
# We intentionally do NOT depend on most bundled libraries here.
# Qt is the only required system dependency per upstream instructions.
DEPEND="
	dev-qt/qtbase:6[gui,widgets,opengl]
	dev-qt/qtsvg:6
	dev-qt/qttools:6
"
RDEPEND="${DEPEND}
	media-sound/carla
	x11-libs/cairo
	media-libs/fontconfig
	media-libs/freetype
	gui-libs/gtk
	gui-libs/libpanel
	gui-libs/gtksourceview
	dev-libs/libcyaml
	media-libs/libsamplerate
	media-libs/libsndfile
	media-libs/lilv
	media-libs/lv2
	media-libs/rubberband
	media-libs/soxr
	media-sound/sox
	media-libs/suil
	x11-libs/libX11
	x11-libs/libXcursor
	x11-libs/libXrandr
	x11-libs/libXinerama
"
BDEPEND="
	dev-build/ninja
	dev-build/meson
	dev-scheme/guile
	virtual/pkgconfig
"

S="${WORKDIR}/${P}"

src_configure() {
	local mymesonargs=(
		-Dbuildtype=$(usex debug debug release)

		# Allow upstream wrap (important)
		-Dzrythm_use_system_deps=false

		# Install paths
		--prefix=/usr
	)

	meson_src_configure
}

src_compile() {
	meson_src_compile
}

src_install() {
	meson_src_install

	# Install upstream custom license file
	if [[ -f "${S}/LICENSES/LicenseRef-ZrythmLicense.txt" ]]; then
		insinto /usr/share/licenses/${PN}
		newins LICENSES/LicenseRef-ZrythmLicense.txt LICENSE
	fi
}
