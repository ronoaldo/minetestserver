#!/bin/bash
set -e
set -x

BASEDIR="$(readlink -f "$(dirname "$0")/..")"
IMG="ghcr.io/ronoaldo/minetestserver:testing"
TMPDIR="$(mktemp -d)"
if [ -t 1 ] ; then 
	export IT=-it
fi

log() {
    echo "$(date "+%Y-%m-%d %H%M%S") $*"
}

cleanup() {
    log "Removing temporary directory ${TMPDIR}"
    rm -rvf "${TMPDIR}"
}

version_from_workflow() {
    # TODO(ronoaldo): proper YAML parser to avoid breaking
    grep "$1"= "${BASEDIR}/.github/workflows/multiarch.yaml" | grep -v export | tail -n 1 | cut -f 2 -d=
}

log "Starting an integration test using IMG=${IMG}"
trap 'cleanup' EXIT

log "Detecting versions from workflow ..."
MT="$(version_from_workflow MINETEST_VERSION)"
MTG="$(version_from_workflow MINETEST_GAME_VERSION)"
IRR="$(version_from_workflow MINETEST_IRRLICHT_VERSION)"

log "Building/tagging test image using versions: ${MT}, ${MTG}, ${IRR}... "
docker build \
    -t "${IMG}" \
    --build-arg MINETEST_VERSION="${MT}" \
    --build-arg MINETEST_GAME_VERSION="${MTG}" \
    --build-arg MINETEST_IRRLICHT_VERSION="${IRR}" \
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
    log "Building and starting test server ..."
    docker build -t ${TEST_IMG} --build-arg BASE_IMAGE=${IMG} ./

    # 2. Prepare/fix the data dir
    mkdir -p data
    # shellcheck disable=2086
    docker run ${IT} --rm \
        -v "$PWD:/server" \
        -u 0:0 \
        ${TEST_IMG} bash -c 'chown -R minetest /server/data'

    # 3. Run the server without the restart loop.
    # shellcheck disable=2086
    docker run ${IT} --rm \
        -v "$PWD/data:/var/lib/minetest" \
        -e NO_LOOP=true \
        ${TEST_IMG}

    popd || exit
else
    log "Error entering ${TMPDIR}"
    exit 1
fi