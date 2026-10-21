# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit optfeature shell-completion

MY_PN="${PN%-bin}"
MY_URI="https://registry.npmjs.org/@opencode"

DESCRIPTION="AI coding agent for the terminal"
HOMEPAGE="https://opencode.ai/
	https://github.com/anomalyco/opencode/"

# Since 2.0 the per-platform binaries are published as npm packages under the
# @opencode scope instead of GitHub release assets. Their tarball names are
# already version stamped, so they can be stored in DISTDIR as they come.
SRC_URI="
	amd64? (
		cpu_flags_x86_avx2? (
			elibc_glibc? ( ${MY_URI}/cli-linux-x64/-/cli-linux-x64-${PV}.tgz )
			elibc_musl? ( ${MY_URI}/cli-linux-x64-musl/-/cli-linux-x64-musl-${PV}.tgz )
		)
		!cpu_flags_x86_avx2? (
			elibc_glibc? ( ${MY_URI}/cli-linux-x64-baseline/-/cli-linux-x64-baseline-${PV}.tgz )
			elibc_musl? ( ${MY_URI}/cli-linux-x64-baseline-musl/-/cli-linux-x64-baseline-musl-${PV}.tgz )
		)
	)
	arm64? (
		elibc_glibc? ( ${MY_URI}/cli-linux-arm64/-/cli-linux-arm64-${PV}.tgz )
		elibc_musl? ( ${MY_URI}/cli-linux-arm64-musl/-/cli-linux-arm64-musl-${PV}.tgz )
	)
"
# The npm tarballs unpack to package/{package.json,bin/opencode}.
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
	dobin package/bin/opencode

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
	local oc="package/bin/opencode"

	# Completions are static scripts printed by the global --completions flag.
	env "${ocenv[@]}" "${oc}" --completions bash \
		> "${T}/${MY_PN}.bash" || die "failed to generate bash completion"
	newbashcomp "${T}/${MY_PN}.bash" "${MY_PN}"

	env "${ocenv[@]}" "${oc}" --completions zsh \
		> "${T}/_${MY_PN}" || die "failed to generate zsh completion"
	newzshcomp "${T}/_${MY_PN}" "_${MY_PN}"

	env "${ocenv[@]}" "${oc}" --completions fish \
		> "${T}/${MY_PN}.fish" || die "failed to generate fish completion"
	newfishcomp "${T}/${MY_PN}.fish" "${MY_PN}"
}

pkg_postinst() {
	elog "opencode is managed by portage here, so do not use 'opencode upgrade'"
	elog "or 'opencode uninstall'. Set OPENCODE_DISABLE_AUTOUPDATE=1 in your"
	elog "environment to stop it from checking for new releases on startup."

	optfeature "plugins and language servers distributed as npm packages" \
		net-libs/nodejs
}
