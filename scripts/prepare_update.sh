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

# check upstream for latest release
if [[ -z "$UPSTREAM_RELEASE" ]]; then
	UPSTREAM_RELEASE="$(git -c 'versionsort.suffix=-' ls-remote --tags --refs --sort='v:refname' upstream 'web-v*' | tail -n1 | grep -Eo '[^\/v]*$')"
fi

# Check the format of the provided vault version
# If this is vYYYY.M.B or YYYY.M.B then fix this automatically to prepend web- or web-v
if [[ "${UPSTREAM_RELEASE}" =~ ^20[0-9]{2}\.[0-9]{1,2}.[0-9]{1} ]]; then
    UPSTREAM_RELEASE="web-v${UPSTREAM_RELEASE}"
elif [[ "${UPSTREAM_RELEASE}" =~ ^v20[0-9]{2}\.[0-9]{1,2}.[0-9]{1} ]]; then
    UPSTREAM_RELEASE="web-${UPSTREAM_RELEASE}"
fi

if [[ web-"$OLD_VERSION" == "${UPSTREAM_RELEASE}" ]]; then
	echo "${OLD_VERSION} is the latest release"
fi

echo "fetching the latest release ${UPSTREAM_RELEASE}"
git fetch upstream refs/tags/${UPSTREAM_RELEASE}:refs/tags/${UPSTREAM_RELEASE}

# also make sure we have the base of the current release
git fetch upstream refs/tags/web-${OLD_VERSION}:refs/tags/web-${OLD_VERSION}

if git rev-parse "${UPSTREAM_RELEASE#web-}" > /dev/null 2>&1; then
	echo "local branch ${UPSTREAM_RELEASE#web-} already exists";
	exit
else
	# add new branch to keep track of our changes
	git checkout ${UPSTREAM_RELEASE} -b ${UPSTREAM_RELEASE#web-}
fi

echo "Preparations complete, you can now run something like the following to apply the patches"
echo 
echo "pushd ${VAULT_FOLDER}"
echo "git cherry-pick web-${OLD_VERSION}..${OLD_VERSION}"
echo "popd"
popd
