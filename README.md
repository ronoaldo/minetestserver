# Minetest Server for Docker Hosting

This is a docker image designed to host [Minetest](https://www.minetest.net)
game servers using Docker.

This is based on Debian Stable (for security patches from upstream), and has
some helper scripts/tools for making building your server easier.

The images can be used on both `linux/amd64` and `linux/arm64` architectures.
This means that you can use this for hosting your server as a docker container
running on Raspberry Pi!

## Why?

The goal of this image is to make the Minetest code, the Game code and all
installed Mods code a single immutable image. That is why we bundle some tools
to help with that. This helps to make each image reproducible snapshot of your
server code, while also trying to isolate as much as possible from the world
data volume.

The recommended way to use this image is to create a `Dockerfile` and add your
custom elements there. Build your image with `docker build` and execute it with
`docker run`. This aproach provides an extra level of protection, since mod
code is always read-only from the running `minetestserver` proccess.

Refer to the [sample](./sample/) server as well as the following instructions on
how to setup your custom server with Docker using this base image.

## Included tools

* **contentdb**: this is a small command line interface made to help installing/
  updating mods from ContentDB, the curated mod repository for Minetest.
* **git**: several mods are available as Git repositories only, so git is bundled
  with the base image to help building the server images.

## Building your Server

You can start building your server easily with the following `Dockerfile`:

    FROM ghcr.io/ronoaldo/minetestserver:stable
    
    USER root
    RUN cd /usr/share/minetest &&\
        contentdb install TenPlus1/ethereal
    
    USER minetest

After that, you can build your server image with `docker build`:

    docker build --tag myserver:latest .

This will bundle a mod (Ethereal NG from TenPlus1) into your image.
You can then test your server with `docker run`:

    docker run -it \
        -p 30000:30000/udp -p 30000:30000/tcp \
        myserver:latest

To stop it, you can hit CTRL+C twice.

## Persisting your world data

To persist your world data, you need to setup a volume for the .minetest folder.
I find it easier to just mount a folder from the host to the container.

First, create a folder and change it to be owned by the container user:

    mkdir -p data
    sudo chown 30000 ./data

Then, bind-mount this to the container when launching your server:

    docker run -it \
        -p 30000:30000/udp -p 30000:30000/tcp \
        -v $PWD/data:/var/lib/minetest:rw \
        myserver:latest

You will see that the folder `./data/.minetest` will be created. You can now
change any settings here and it will persist if you stop/start the container
again.

## Change default settings

The default container command launches the server with a basic configuration,
provided by the Minetest distribution, and placed at
`/etc/minetest/minetest.conf` inside the final image.

One easy way to start changing it is to copy the file from the container:

    docker run -it \
        -v $PWD/data:/var/lib/minetest:rw \
        myserver:latest \
        cp /etc/minetest/minetest.conf /var/lib/minetest/

This will create a new file in your `./data/` folder named `minetest.conf`. 

It may be needed to fix permissions in the data folder in order to make changes
to this file or make world backups. To fix that, try this:

    sudo chgrp -R $(id -g) ./data
    sudo chmod -R g+rw ./data

The final step is to launch you server with the new settings. We provide a
convenient [wrapper](./minetest-wrapper.sh) to restart your server automatically
if it crashes. So, to change the settings, you can then launch the container
like this:

    docker run -it \
        -p 30000:30000/udp -p 30000:30000/tcp \
        -v $PWD/data:/var/lib/minetest:rw \
        myserver:latest \
        minetest-wrapper.sh --config /var/lib/minetest/minetest.conf

