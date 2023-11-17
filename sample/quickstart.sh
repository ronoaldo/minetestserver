#!/bin/bash
set -x
set -e

# 1. (Re)build the image
docker build -t myserver:latest ./

# 2. Prepare/fix the data dir
mkdir -p data
docker run -it --rm \
	-v "$PWD:/server" \
	-u 0:0 \
	myserver:latest bash -c 'chown -R minetest /server/data'

# 3. Run the server
docker run -it --rm --name=myserver \
	-v "$PWD/data:/var/lib/minetest" \
	-p 30000:30000/udp -p 30000:30000/tcp \
	-e NO_LOOP=true \
	myserver:latest
