# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit optfeature shell-completion

MY_PN="${PN%-bin}"
MY_URI="https://github.com/anomalyco/opencode/releases/download/v${PV}"

DESCRIPTION="AI coding agent for the terminal"
HOMEPAGE="https://opencode.ai/
	https://github.com/anomalyco/opencode/"

# Upstream release assets are not version stamped, so rename them to avoid
# collisions in DISTDIR between versions.
SRC_URI="
	amd64? (
		cpu_flags_x86_avx2? (
			elibc_glibc? ( ${MY_URI}/${MY_PN}-linux-x64.tar.gz -> ${P}-linux-x64.tar.gz )
			elibc_musl? ( ${MY_URI}/${MY_PN}-linux-x64-musl.tar.gz -> ${P}-linux-x64-musl.tar.gz )
		)
		!cpu_flags_x86_avx2? (
			elibc_glibc? ( ${MY_URI}/${MY_PN}-linux-x64-baseline.tar.gz -> ${P}-linux-x64-baseline.tar.gz )
			elibc_musl? ( ${MY_URI}/${MY_PN}-linux-x64-baseline-musl.tar.gz -> ${P}-linux-x64-baseline-musl.tar.gz )
		)
	)
	arm64? (
		elibc_glibc? ( ${MY_URI}/${MY_PN}-linux-arm64.tar.gz -> ${P}-linux-arm64.tar.gz )
		elibc_musl? ( ${MY_URI}/${MY_PN}-linux-arm64-musl.tar.gz -> ${P}-linux-arm64-musl.tar.gz )
	)
"
S="${WORKDIR}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="cpu_flags_x86_avx2"

# Single-file bun executable with an appended asset archive; stripping or
# otherwise rewriting it corrupts the embedded payload.
RESTRICT="strip"
QA_PREBUILT="usr/bin/${MY_PN}"

# opencode shells out to rg for its glob/grep/find tools and downloads its own
# copy into ~/.cache/opencode/bin when one is not on PATH. git is used for
# project detection, diffs and the pr/github subcommands.
RDEPEND="
	dev-vcs/git
	sys-apps/ripgrep
"

src_install() {
	dobin "${MY_PN}"

	# The bun runtime opens the ftrace marker on startup; nothing that matters
	# is written to it here, so let the sandbox swallow the access.
	addpredict /sys/kernel/debug/tracing/trace_marker

	# Point HOME and the XDG dirs at ${T} so the binary only scribbles inside
	# the build dir while generating the completions below.
	local -a ocenv=(
		HOME="${T}"
		XDG_CACHE_HOME="${T}"
		XDG_CONFIG_HOME="${T}"
		XDG_DATA_HOME="${T}"
		XDG_STATE_HOME="${T}"
		OPENCODE_DISABLE_AUTOUPDATE=1
		OPENCODE_DISABLE_MODELS_FETCH=1
	)

	# The bundled yargs completion generator picks its flavour from ${SHELL}
	# rather than from an argument, so ask for each one in turn. There is no
	# fish flavour upstream.
	env "${ocenv[@]}" SHELL=/bin/bash "./${MY_PN}" completion \
		> "${T}/${MY_PN}.bash" || die "failed to generate bash completion"
	newbashcomp "${T}/${MY_PN}.bash" "${MY_PN}"

	env "${ocenv[@]}" SHELL=/bin/zsh "./${MY_PN}" completion \
		> "${T}/_${MY_PN}" || die "failed to generate zsh completion"
	newzshcomp "${T}/_${MY_PN}" "_${MY_PN}"
}

pkg_postinst() {
	elog "opencode is managed by portage here, so do not use 'opencode upgrade'"
	elog "or 'opencode uninstall'. Set OPENCODE_DISABLE_AUTOUPDATE=1 in your"
	elog "environment to stop it from checking for new releases on startup."

	optfeature "plugins and language servers distributed as npm packages" \
		net-libs/nodejs
}
