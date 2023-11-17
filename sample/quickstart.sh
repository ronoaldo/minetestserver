#!/bin/bash
# shellcheck disable=2086
set -x
set -e

# 0. Setup some environment variables for testing
if [ -n "$1" ]; then
	export BUILD_ARGS="--build-arg BASE_IMAGE=$1"
fi
if [ -t 1 ] ; then 
	export IT=-it
fi

# 1. (Re)build the image
docker build -t myserver:latest ${BUILD_ARGS} ./

# 2. Prepare/fix the data dir
mkdir -p data
docker run ${IT} --rm \
	-v "$PWD:/server" \
	-u 0:0 \
	myserver:latest bash -c 'chown -R minetest /server/data'

# 3. Run the server without the restart loop.
docker run ${IT} --rm --name minetest_server \
	-v "$PWD/data:/var/lib/minetest" \
	-p 30000:30000/udp -p 30000:30000/tcp \
	-e NO_LOOP=true \
	myserver:latest
