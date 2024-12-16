#!/bin/bash
set -e
[ x"${DEBUG}" = x"true" ] && set -x

export LUANTI_VERSION MINETEST_GAME_VERSION LUAJIT_VERSION

BASEDIR="$(readlink -f "$(dirname "$0")/..")"
IMG="ghcr.io/ronoaldo/luantiserver:testing"
TMPDIR="$(mktemp -d)"
if [ -t 1 ] ; then 
	export IT=-it
fi

log() {
    echo "[integration-tests] $(date "+%Y-%m-%d %H%M%S") $*"
}

cleanup() {
    RET=$?
    log "Exiting with ${RET} status..."
    if [ "${CLEANUP}" = "true" ]; then
        log "Removing temporary directory ${TMPDIR}"
        rm -rvf "${TMPDIR}"
    fi
}

version_from_workflow() {
    # If the variable is defined already, use it
    if [ "${!1}" != "" ]; then
        echo -n "${!1}"
        return
    fi
    # Else, check if the variable can be parsed from YAML, returning the first value
    # configured by the workflow file.
    yq -r '.jobs["multiarch-build"].strategy.matrix.include[].args' < .github/workflows/multiarch.yaml |\
        grep "$1"= | tail -n 1 | cut -f 2 -d=
}

install_deps() {
    yq --version 2>/dev/null >/dev/null || {
        sudo apt-get install -yq yq
    }
}

log "Starting an integration test using IMG=${IMG}"
trap 'cleanup' EXIT

log "Installing required dependencies ..."
install_deps

log "Detecting versions from workflow ..."
LT="$(version_from_workflow LUANTI_VERSION)"
MTG="$(version_from_workflow MINETEST_GAME_VERSION)"
LUA="$(version_from_workflow LUAJIT_VERSION)"

log "Building/tagging test image using versions:"
log "    Luanti=${LT}"
log "    Minetest_Game=${MTG}"
log "    LuaJIT=${LUA}"

docker build \
    -t "${IMG}" \
    --build-arg LUANTI_VERSION="${LT}" \
    --build-arg MINETEST_GAME_VERSION="${MTG}" \
    --build-arg LUAJIT_VERSION="${LUA}" \
    ./

log "Using ${TMPDIR} as a temporary directory"

cp -rv "${BASEDIR}"/sample/* "${TMPDIR}"
if pushd "${TMPDIR}" ; then
    log "Cleaning up previous data (if any)"
    rm -rvf "${TMPDIR}/data"

    log "Installing local world shutdown hook"
    mkdir -p "${TMPDIR}/data"
    # shellcheck disable=2102
    cp -rv "${BASEDIR}"/test/testdata/.minetest "${TMPDIR}/data"

    TEST_IMG="gcr.io/ronoaldo/myserver:testsrv"
    log "Building and starting test server ${TEST_IMG}..."
    docker build -t ${TEST_IMG} --build-arg BASE_IMAGE=${IMG} ./

    # 2. Prepare/fix the data dir
    mkdir -p data
    # shellcheck disable=2086
    docker run ${IT} --rm \
        -v "$PWD:/server" \
        -u 0:0 \
        ${TEST_IMG} bash -c 'chown -R luanti /server/data'
    log "Listing installed games:"
    docker run --rm ${TEST_IMG} luantiserver --gameid list

    # 3. Run the server without the restart loop.
    # shellcheck disable=2086
    log "Testing a local execution with local mods"
    docker run ${IT} --rm \
        -v "$PWD/data:/var/lib/luanti" \
        -e NO_LOOP=true \
        ${TEST_IMG}

    popd || exit
else
    log "Error entering ${TMPDIR}"
    exit 1
fi