# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

# Upstream tags the release as "v1.3-latest".
MY_TAG="v${PV}-latest"
MY_P="Just-a-Sample-${PV}-latest"

# Just a Sample vendors the following via CMake FetchContent / git submodules.
# GitHub source archives ship none of them, so we fetch each pinned revision
# ourselves and point FetchContent at the unpacked trees (see src_configure).
JUCE_V="8.0.12"
BUNGEE_V="2.4.10"
MELATONIN_BLUR_C="fcc18578d9db3f9400c74ee1bb2eb1070ee959f9"
MELATONIN_INSPECTOR_C="9c483f865854d83fe9873e1c20e3fd772f695f80"
LEAF_C="8d86c4e96ac48740da34f24c9f995bc3c4b3b2a0"
READERWRITERQUEUE_C="211616e0554f93152ab3108b8d93fbc23174a9d9"
# Bungee's own submodules.
EIGEN_C="c29c800126982c561e8d0b9255dc65474cd98de3"
CXXOPTS_C="4bf61f08697b110d9e3991864650a405b3dd515d"
PFFFT_C="02fe7715a5bf8bfd914681c53429600f94e0f536"

DESCRIPTION="A modern, open-source audio sampler VST3 plugin"
HOMEPAGE="https://github.com/BOBONA/Just-a-Sample https://bobona.github.io/just-a-sample/"
SRC_URI="
	https://github.com/BOBONA/Just-a-Sample/archive/refs/tags/${MY_TAG}.tar.gz -> ${P}.tar.gz
	https://github.com/juce-framework/JUCE/archive/refs/tags/${JUCE_V}.tar.gz -> juce-${JUCE_V}.tar.gz
	https://github.com/bungee-audio-stretch/bungee/archive/refs/tags/v${BUNGEE_V}.tar.gz -> bungee-${BUNGEE_V}.tar.gz
	https://github.com/sudara/melatonin_blur/archive/${MELATONIN_BLUR_C}.tar.gz -> melatonin_blur-${MELATONIN_BLUR_C}.tar.gz
	https://github.com/sudara/melatonin_inspector/archive/${MELATONIN_INSPECTOR_C}.tar.gz -> melatonin_inspector-${MELATONIN_INSPECTOR_C}.tar.gz
	https://github.com/spiricom/LEAF/archive/${LEAF_C}.tar.gz -> leaf-${LEAF_C}.tar.gz
	https://github.com/cameron314/readerwriterqueue/archive/${READERWRITERQUEUE_C}.tar.gz -> readerwriterqueue-${READERWRITERQUEUE_C}.tar.gz
	https://gitlab.com/libeigen/eigen/-/archive/${EIGEN_C}/eigen-${EIGEN_C}.tar.gz
	https://github.com/jarro2783/cxxopts/archive/${CXXOPTS_C}.tar.gz -> cxxopts-${CXXOPTS_C}.tar.gz
	https://bitbucket.org/jpommier/pffft/get/${PFFFT_C}.tar.gz -> pffft-${PFFFT_C}.tar.gz
"

# just-a-sample: MIT; JUCE: AGPL-3 (or commercial); bungee, eigen: MPL-2.0;
# pffft, readerwriterqueue: BSD; melatonin_*, cxxopts, LEAF: MIT.
LICENSE="MIT AGPL-3 MPL-2.0 BSD"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="mirror"

RDEPEND="
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	virtual/glu
	virtual/jack
	virtual/opengl
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXext
	x11-libs/libXinerama
	x11-libs/libXrandr
	x11-libs/libXrender
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

S="${WORKDIR}/${MY_P}"

DOCS=( README.md FEATURES.md )

src_prepare() {
	local bungee="${WORKDIR}/bungee-${BUNGEE_V}"

	# Drop the vendored dependencies into the locations the build expects.
	# readerwriterqueue is a git submodule; bungee pulls eigen/cxxopts/pffft
	# as submodules of its own.
	rm -rf External/readerwriterqueue || die
	mv "${WORKDIR}/readerwriterqueue-${READERWRITERQUEUE_C}" \
		External/readerwriterqueue || die

	mkdir -p "${bungee}/submodules" || die
	rm -rf "${bungee}"/submodules/{eigen,cxxopts,pffft} || die
	mv "${WORKDIR}/eigen-${EIGEN_C}" "${bungee}/submodules/eigen" || die
	mv "${WORKDIR}/cxxopts-${CXXOPTS_C}" "${bungee}/submodules/cxxopts" || die
	mv "${WORKDIR}"/jpommier-pffft-* "${bungee}/submodules/pffft" || die

	# JUCE derives each module's name from its directory's basename, so the
	# melatonin modules must live in bare "melatonin_blur"/"melatonin_inspector"
	# directories (not the commit-suffixed unpack names).
	mv "${WORKDIR}/melatonin_blur-${MELATONIN_BLUR_C}" \
		"${WORKDIR}/melatonin_blur" || die
	mv "${WORKDIR}/melatonin_inspector-${MELATONIN_INSPECTOR_C}" \
		"${WORKDIR}/melatonin_inspector" || die

	# Overriding FETCHCONTENT_SOURCE_DIR_* skips FetchContent's PATCH_COMMAND
	# step, so the two upstream patches must be applied by hand.
	cd "${bungee}" || die
	eapply -p0 "${S}/Patches/bungee_lower_cmake_and_set_num_octaves.patch"

	# LEAF ships CRLF line endings; normalise the touched files so the LF
	# patch applies (upstream relies on "git apply --ignore-whitespace").
	local leaf="${WORKDIR}/LEAF-${LEAF_C}"
	sed -i 's/\r$//' "${leaf}"/leaf/leaf-config.h "${leaf}"/leaf/leaf.h || die
	cd "${leaf}" || die
	eapply -p0 "${S}/Patches/leaf_more_selective_imports.patch"

	cd "${S}" || die
	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		# Fully offline: use the trees we unpacked, never touch the network.
		-DFETCHCONTENT_FULLY_DISCONNECTED=ON
		-DFETCHCONTENT_SOURCE_DIR_JUCE="${WORKDIR}/JUCE-${JUCE_V}"
		-DFETCHCONTENT_SOURCE_DIR_BUNGEE="${WORKDIR}/bungee-${BUNGEE_V}"
		-DFETCHCONTENT_SOURCE_DIR_MELATONIN_BLUR="${WORKDIR}/melatonin_blur"
		-DFETCHCONTENT_SOURCE_DIR_MELATONIN_INSPECTOR="${WORKDIR}/melatonin_inspector"
		-DFETCHCONTENT_SOURCE_DIR_LEAF="${WORKDIR}/LEAF-${LEAF_C}"

		# Respect the user's CFLAGS: don't force -mavx2/-ffast-math/ccache.
		-DJAS_ENABLE_AVX2=OFF
		-DJAS_FAST_MATH=OFF
		-DUSE_CCACHE=OFF
	)
	cmake_src_configure
}

src_install() {
	local vst3
	vst3=$(find "${BUILD_DIR}" -type d -name '*.vst3' -print -quit) || die
	[[ -n ${vst3} ]] || die "could not locate built VST3 bundle"

	# cp -r preserves the executable bit on the module .so.
	dodir "/usr/$(get_libdir)/vst3"
	cp -r "${vst3}" "${ED}/usr/$(get_libdir)/vst3/" || die

	einstalldocs
}
