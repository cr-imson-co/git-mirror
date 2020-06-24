#!/bin/bash
#
# cr.imson.co
#
# git mirror utility
# @author Damian Bushong <katana@odios.us>
#

# set sane shell env options
set -o errexit -o pipefail -o noclobber -o nounset

DIR="$(dirname "$(readlink -f "$0")")"

pushd $DIR > /dev/null

if [ -z "$2" ]; then
    echo usage: $0 \<gitlab repo\> \<github repo\>
    exit 1
fi

GITLAB_REPO_URI=$1
GITHUB_REPO_URI=$2

GITLAB_REPO_DIR=$(mktemp -d -p $DIR)
GITHUB_REPO_DIR=$(mktemp -d -p $DIR)
git clone --depth 1 $GITLAB_REPO_URI $GITLAB_REPO_DIR
git clone --depth 1 $GITHUB_REPO_URI $GITHUB_REPO_DIR

set +o errexit
diff -x .git -r $GITLAB_REPO_DIR $GITHUB_REPO_DIR >/dev/null
DIFF_STATUS=$?
set -o errexit

# todo: support mirroring updates to submodules

if [ $DIFF_STATUS -ne 0 ]; then
    rsync -avr --delete --exclude='.git' $GITLAB_REPO_DIR/ $GITHUB_REPO_DIR

    pushd $GITLAB_REPO_DIR > /dev/null
        if [ -f "$GITLAB_REPO_DIR/.gitmodules" ]; then
            git submodule update --init
            _GIT_MODULES=$(git submodule foreach -q 'echo $name!`git remote get-url origin`')
            GIT_MODULES=($_GIT_MODULES)
        fi
    popd > /dev/null

    pushd $GITHUB_REPO_DIR > /dev/null
        if [ -f "$GITLAB_REPO_DIR/.gitmodules" ]; then
            for _GIT_MODULE in "${GIT_MODULES[@]}"; do
                SUBMODULE_PATH=$(echo $_GIT_MODULE | cut -d '!' -f1)
                SUBMODULE_URI=$(echo $_GIT_MODULE | cut -d '!' -f2)

                echo checking for submodule $SUBMODULE_PATH

                set +o errexit
                git submodule status | grep $SUBMODULE_PATH
                SUBMODULE_EXISTS=$?
                set -o errexit
                if [ $SUBMODULE_EXISTS -ne 0 ]; then
                    echo adding submodule $SUBMODULE_PATH
                    git submodule add $SUBMODULE_URI $SUBMODULE_PATH
                fi
            done
        fi
        git add -A .
        git commit -m '[jenkins] Automated git mirroring from cr.imson.co repository'
        git push origin master -f
    popd > /dev/null
fi

rm -rf "$GITLAB_REPO_DIR" "$GITHUB_REPO_DIR"

popd > /dev/null
