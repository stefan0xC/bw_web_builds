#!/usr/bin/env bash
set -o pipefail -o errexit
BASEDIR=$(RL=$(readlink -n "$0"); SP="${RL:-$0}"; dirname "$(cd "$(dirname "${SP}")"; pwd)/$(basename "${SP}")")

# Error handling
handle_error() {
    read -n1 -r -p "FAILED: line $1, exit code $2. Press any key to exit..." _
    exit 1
}
trap 'handle_error $LINENO $?' ERR

# Load default script environment variables
# shellcheck source=.script_env
. "${BASEDIR}/.script_env"

pushd "${VAULT_FOLDER}"

OLD_VERSION=$(get_web_vault_version)

# check for upstream repository
UPSTREAM=$(git remote | grep "^upstream\$")
if [[ -z "$UPSTREAM" ]]; then
	# add upstream as remote repository to clients
	git remote add upstream https://github.com/bitwarden/clients.git
	# don't pull all remote tags
	git config remote.upstream.tagOpt --no-tags
fi

# also make sure we have the base of the current release
git fetch upstream refs/tags/web-${OLD_VERSION}:refs/tags/web-${OLD_VERSION}

# create a patch file compatible
git diff web-${OLD_VERSION}..${OLD_VERSION} --abbrev=10 -- \
	':!apps/web/src/favicon.ico' \
	':!apps/web/src/images/logo-dark@2x.png' \
	':!apps/web/src/images/logo-white@2x.png' \
	':!apps/web/src/images/icon-white.png' \
	':!apps/web/src/images/icon-dark.png' \
	':!apps/web/src/images/icons/android-chrome-192x192.png' \
	':!apps/web/src/images/icons/android-chrome-512x512.png' \
	':!apps/web/src/images/icons/apple-touch-icon.png' \
	':!apps/web/src/images/icons/favicon-16x16.png' \
	':!apps/web/src/images/icons/favicon-32x32.png' \
	':!apps/web/src/images/icons/mstile-150x150.png' \
	':!apps/web/src/images/icons/safari-pinned-tab.svg' \
	':!apps/web/src/app/admin-console/icons/admin-console-logo.ts' \
	':!apps/web/src/app/layouts/password-manager-logo.ts' \
	':!libs/auth/src/angular/icons/bitwarden-logo.icon.ts' \
	':!package.json' \
	':!bitwarden_license/' \
	':!apps/browser' \
	':!apps/cli' \
	':!apps/desktop' \
	':!.github/' \
	> ${OLD_VERSION}.patch
popd
