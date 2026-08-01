# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

MY_PV="${PV/_rc/-RC}"

DESCRIPTION="Open-world single-player space-combat, roleplaying and exploration game"
HOMEPAGE="https://fractalsoftworks.com/"
SRC_URI="https://f005.backblazeb2.com/file/fractalsoftworks/release/starsector_linux-${MY_PV}.zip -> ${P}.zip"
S="${WORKDIR}/${PN}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64"

# Proprietary prebuilt binary bundling its own JRE and native libraries.
RESTRICT="bindist mirror strip"

QA_PREBUILT="*"

RDEPEND="
	media-libs/alsa-lib
	virtual/opengl
	x11-libs/libX11
	x11-libs/libXcursor
	x11-libs/libXrandr
	x11-libs/libXxf86vm
"
BDEPEND="app-arch/unzip"

src_prepare() {
	default

	# Player data is redirected to ${STARSECTOR_HOME} at runtime.
	rmdir mods saves screenshots || die

	# Drop the Windows and macOS launchers.
	rm -f starsector.bat starsector.bat32 starsector_minimal.bat \
		starsector.command || die

	# Point the bundled launcher's writable paths at the per-user directory
	# set up by the /usr/bin/starsector wrapper.
	sed -i \
		-e 's|paths.saves=./saves|paths.saves=${STARSECTOR_HOME}/saves|' \
		-e 's|paths.screenshots=./screenshots|paths.screenshots=${STARSECTOR_HOME}/screenshots|' \
		-e 's|paths.mods=./mods|paths.mods=${STARSECTOR_HOME}/mods|' \
		-e 's|paths.logs=\.|paths.logs=${STARSECTOR_HOME}|' \
		starsector.sh || die
}

src_install() {
	# cp preserves the executable bits and symlinks of the bundled JRE and
	# native libraries, which doins would strip.
	dodir /opt
	cp -r "${S}" "${ED}/opt/" || die

	# The archive ships programs without the other-execute bit, so a
	# regular user cannot run them from the root-owned /opt install.
	local dst="${ED}/opt/${PN}"
	find "${dst}" -type f -exec chmod a+r {} + || die
	chmod a+rx "${dst}"/starsector.sh || die
	find "${dst}"/jre_linux/bin -type f -exec chmod a+rx {} + || die
	chmod a+rx "${dst}"/jre_linux/lib/jspawnhelper || die

	dobin "${FILESDIR}"/starsector

	newicon -s 16 graphics/ui/s_icon16.png starsector.png
	newicon -s 32 graphics/ui/s_icon32.png starsector.png
	newicon -s 64 graphics/ui/s_icon64.png starsector.png

	make_desktop_entry --eapi9 \
		starsector \
		--name Starsector \
		--icon starsector \
		--categories "Game;RolePlaying;" \
		--entry "GenericName=Space-combat roleplaying game"
}
