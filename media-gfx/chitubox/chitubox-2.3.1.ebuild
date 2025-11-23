# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit xdg

DESCRIPTION="All-in-one SLA/DLP/LCD Slicer"
HOMEPAGE="https://www.chitubox.com/download.html"

# Binary package
# Note: chitubox-basic.desktop and chitubox-basic.xml must be placed in files/ directory
SRC_URI="
	https://sac.chitubox.com/software/download.do?installerUrl=https%3A%2F%2Fdownload.chitubox.com%2F17839%2Fv2.3.1%2FCHITUBOX_Basic_linux_Installer_2.3.1&softwareId=17839&softwareVersionId=v2.3.1 -> ${P}.bin
"

LICENSE="LicenseRef-CHITUBOX"
SLOT="0"
KEYWORDS="-* amd64"
IUSE=""

# Binary package, no stripping
RESTRICT="strip"

# Runtime dependencies
RDEPEND="
	app-crypt/mit-krb5
	dev-libs/glib:2
	media-gfx/hicolor-icon-theme
	sys-apps/dbus
	sys-libs/zlib
	x11-libs/libX11
	x11-libs/libxkbcommon[X]
	x11-libs/xcb-util-keysyms
	x11-libs/xcb-util-image
	x11-libs/xcb-util-renderutil
	x11-libs/xcb-util-wm
"

# Build-time dependencies
BDEPEND="
	media-gfx/icoutils
	media-libs/fontconfig
	media-libs/freetype:2
"

S="${WORKDIR}"

src_unpack() {
	# Only unpack the installer binary, rename it for convenience
	cp "${DISTDIR}/${P}.bin" "${WORKDIR}/chitubox-installer" || die
	chmod +x "${WORKDIR}/chitubox-installer" || die
	
	# Copy desktop and mime files from files/ directory
	cp "${FILESDIR}/chitubox-basic.desktop" "${WORKDIR}/" || die
	cp "${FILESDIR}/chitubox-basic.xml" "${WORKDIR}/" || die
}

src_install() {
	local install_root="${WORKDIR}/opt/CHITUBOX_Basic"

	# Run installer (requires root, so we do it in src_install)
	# The installer needs to run as root, which is why we can't do this in src_compile
	"${WORKDIR}/chitubox-installer" \
		--root "${install_root}" \
		--accept-licenses \
		--no-size-checking \
		--accept-messages \
		--confirm-command \
		install || die "Installer failed"

	# Clean up unnecessary files
	rm -f "${install_root}"/Uninstall* || die
	rm -f "${install_root}/InstallationLog.txt" || die
	# Remove Windows executables (ffmpeg .exe's)
	rm -f "${install_root}"/bin/Resources/DependentSoftware/recordOrShot/*.exe || die

	# Install license
	insinto /usr/share/licenses/${PN}
	newins "${install_root}/Licenses/LICENSE.txt" LICENSE

	# Install binary data
	# Use cp -r to preserve permissions and structure
	dodir /opt
	cp -r "${install_root}" "${ED}/opt/" || die "Failed to copy application files"

	# Make the main script executable (should already be, but ensure it)
	fperms +x /opt/CHITUBOX_Basic/CHITUBOX_Basic.sh

	# Create launcher symlink
	dosym /opt/CHITUBOX_Basic/CHITUBOX_Basic.sh /usr/bin/chitubox-basic

	# Install desktop file
	insinto /usr/share/applications
	doins "${WORKDIR}/chitubox-basic.desktop"

	# Extract icon from ICO file
	icotool --extract "${install_root}/bin/Resources/Image/SoftwareIcon/freeIcon.ico" --output "${WORKDIR}" || die
	insinto /usr/share/icons/hicolor/256x256/apps
	newins "${WORKDIR}/freeIcon_1_256x256x32.png" chitubox-basic.png

	# Install MIME type
	insinto /usr/share/mime/packages
	doins "${WORKDIR}/chitubox-basic.xml"
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	xdg_mimeinfo_database_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	xdg_mimeinfo_database_update
}

