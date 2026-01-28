EAPI=8
inherit udev

DESCRIPTION="XP-Pen tablet driver (unofficial ebuild)
"
HOMEPAGE="https://www.xp-pen.com/"
SRC_URI="https://download01.xp-pen.com/file/2025/02/XPPenLinux4.0.7-250117.tar.gz"

LICENSE="EULA"
SLOT="0"
KEYWORDS=""
IUSE=""

# The upstream tarball expands to a directory named XPPenLinux4.0.7-250117
S="${WORKDIR}/XPPenLinux4.0.7-250117"

src_unpack() {
	unpack ${A}
}

src_prepare() {
	# call default to satisfy eapply/epatch checks (no patches applied)
	default
}

src_install() {
	# install the bundled application tree under /usr/lib/pentablet
	dodir /usr/lib/pentablet
	if ! cp -a "${S}/App/usr/lib/pentablet" "${D}/usr/lib/"; then
		die "Failed to install pentablet files"
	fi

	# install udev rule
	dodir /lib/udev/rules.d
	if [ -f "${S}/App/lib/udev/rules.d/10-xp-pen.rules" ]; then
		cp "${S}/App/lib/udev/rules.d/10-xp-pen.rules" "${D}/lib/udev/rules.d/10-xp-pen.rules" || die "Failed to install udev rule"
	fi

	# install desktop entry and icon
	dodir /usr/share/applications
	dodir /usr/share/icons/hicolor/256x256/apps
	if [ -f "${S}/App/usr/share/applications/xppentablet.desktop" ]; then
		cp "${S}/App/usr/share/applications/xppentablet.desktop" "${D}/usr/share/applications/" || die "Failed to install desktop file"
	fi
	if [ -f "${S}/App/usr/share/icons/hicolor/256x256/apps/xppentablet.png" ]; then
		cp "${S}/App/usr/share/icons/hicolor/256x256/apps/xppentablet.png" "${D}/usr/share/icons/hicolor/256x256/apps/" || die "Failed to install icon"
	fi

	# install autostart file if present
	dodir /etc/xdg/autostart
	if [ -f "${S}/App/etc/xdg/autostart/xppentablet.desktop" ]; then
		cp "${S}/App/etc/xdg/autostart/xppentablet.desktop" "${D}/etc/xdg/autostart/" || die "Failed to install autostart file"
	fi

	# install documentation
	dodoc "${S}/App/usr/lib/pentablet/doc/EULA" "${S}/App/usr/lib/pentablet/doc/ThirdPartyLibraries.html"

	# set permissions similar to the original installer
	if [ -f "${D}/usr/lib/pentablet/PenTablet" ]; then
		chmod 0555 "${D}/usr/lib/pentablet/PenTablet" || die
	fi
	if [ -f "${D}/usr/lib/pentablet/PenTablet.sh" ]; then
		chmod 0755 "${D}/usr/lib/pentablet/PenTablet.sh" || die
	fi

	# make conf writable by package maintainer (keeps behaviour of upstream installer)
	confdir="${D}/usr/lib/pentablet/conf/xppen"
	if [ -d "${confdir}" ]; then
		# keep the directory accessible but avoid world-writable permissions
		chmod 0755 "${confdir}" || die
		for f in config.xml language.ini name_config.ini dialogpos.ini; do
			if [ -f "${confdir}/$f" ]; then
				chmod 0644 "${confdir}/$f" || die
			fi
		done
	fi

	# resource file
	if [ -f "${D}/usr/lib/pentablet/resource.rcc" ]; then
		chmod 0644 "${D}/usr/lib/pentablet/resource.rcc" || die
	fi
}

pkg_postinst() {
	# reload udev rules so device permissions take effect immediately
	udev_reload
	elog "xppentablet has been installed to /usr/lib/pentablet and related system files.\n"
	elog "Notes:\n - A udev rule was installed to /lib/udev/rules.d; the rules were reloaded. Re-plug your device if it does not appear.\n - If this is the first installation you may need to reboot for everything to work properly."
}

pkg_prerm() {
	# no special pre-removal handling required
	:
}

pkg_postrm() {
	udev_reload
	# upstream uninstaller simply removes the installed tree. Gentoo will handle files in ${D}.
	:
}
