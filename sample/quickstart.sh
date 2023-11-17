#!/bin/bash
set -x
set -e

if [ -n "$1" ]; then
	export BUILD_ARGS="--build-arg BASE_IMAGE=$1"
fi

# 1. (Re)build the image
# shellcheck disable=2086
docker build -t myserver:latest ${BUILD_ARGS} ./

# 2. Prepare/fix the data dir
mkdir -p data
docker run -it --rm \
	-v "$PWD:/server" \
	-u 0:0 \
	myserver:latest bash -c 'chown -R minetest /server/data'

# 3. Run the server without the restart loop.
docker run -it --rm --name minetest_server \
	-v "$PWD/data:/var/lib/minetest" \
	-p 30000:30000/udp -p 30000:30000/tcp \
	-e NO_LOOP=true \
	myserver:latest
