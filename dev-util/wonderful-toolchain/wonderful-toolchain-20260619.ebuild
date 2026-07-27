# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Wonderful Toolchain - development toolchain for retro consoles and handhelds"
HOMEPAGE="https://wonderful.asie.pl/"

# The bootstrap tarballs live at a rolling (unversioned) URL upstream, so the
# fetched contents may drift from ${PV}. This mirrors the wf-installer.sh script.
BOOTSTRAP_URI="https://wonderful.asie.pl/bootstrap"
SRC_URI="
	amd64? ( ${BOOTSTRAP_URI}/wf-bootstrap-x86_64.tar.gz -> ${P}-x86_64.tar.gz )
	arm64? ( ${BOOTSTRAP_URI}/wf-bootstrap-aarch64.tar.gz -> ${P}-aarch64.tar.gz )
"

# wf-installer.sh itself is MIT; the toolchain it fetches carries assorted licenses.
LICENSE="MIT all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"

# Prebuilt binary bootstrap; the URL is not mirrorable and must not be stripped.
RESTRICT="bindist mirror strip"
QA_PREBUILT="*"
QA_PRESTRIPPED="*"

# wf-pacman needs a download tool to populate the toolchain.
RDEPEND="net-misc/curl"

INSTALL_PATH="/opt/wonderful"
S="${WORKDIR}"

src_install() {
	# The bootstrap tarball extracts bin/wf-pacman et al. directly into ${S};
	# copy the tree verbatim to preserve permissions and symlinks.
	dodir "${INSTALL_PATH%/*}"
	cp -a "${S}" "${ED}${INSTALL_PATH}" || die "failed to install bootstrap tree"

	# ${S} (WORKDIR) is mode 0700, which cp -a carries over to ${INSTALL_PATH},
	# hiding the whole tree from unprivileged users. Restore world read/traverse
	# (a+rX only adds execute to directories and already-executable files).
	chmod -R a+rX "${ED}${INSTALL_PATH}" || die "failed to fix permissions"

	if [[ ! -f "${ED}${INSTALL_PATH}/bin/wf-pacman" ]]; then
		die "bootstrap extraction failed (corrupt file?)"
	fi

	# Export WONDERFUL_TOOLCHAIN and add wf- programs to PATH, matching the
	# recommended environment configuration from wf-installer.sh.
	newenvd - 99wonderful <<-EOF
		WONDERFUL_TOOLCHAIN="${INSTALL_PATH}"
		PATH="${INSTALL_PATH}/bin"
	EOF
}

pkg_postinst() {
	# wf-pacman -Syu populates/updates the toolchain over the network, which
	# cannot happen inside the build sandbox. Do it here, non-fatally.
	elog "Updating Wonderful Toolchain base (wf-tools)..."
	if ! "${EROOT}${INSTALL_PATH}/bin/wf-pacman" -Syu --noconfirm wf-tools; then
		ewarn "wf-pacman failed to update the toolchain base."
		ewarn "Run the following manually once network is available:"
		ewarn "    ${INSTALL_PATH}/bin/wf-pacman -Syu wf-tools"
	fi

	elog ""
	elog "Log out and back in (or 'source /etc/profile') to pick up"
	elog "WONDERFUL_TOOLCHAIN and the updated PATH."
	elog ""
	elog "Note: wf-pacman manages files under ${INSTALL_PATH} that are not"
	elog "tracked by portage and will not be removed on unmerge."
	elog "To learn more, visit: https://wonderful.asie.pl/wiki/"
}
