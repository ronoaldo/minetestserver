# Minetest Server for Docker Hosting

This is a docker image designed to host [Minetest](https://www.minetest.net)
game servers using Docker images.

This is based on Debian Stable (for security patches from upstream), and has
some helper scripts/tools for making building your server easier.

## Included tools

* **contentdb**: this is a small command line interface made to help installing/
  upgrading mods from the command-line.
* **git**: several mods are available as Git repositories only, so git is bundled
  with the base image to help building the server images.

## Building your Server

You can start building your server easily with the following `Dockerfile`:

    FROM ghcr.io/ronoaldo/minetestserver:stable-5
    
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
`/etc/minetest/minetest.conf`.

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

Finally, just launch you server with the new settings!

    docker run -it \
        -p 30000:30000/udp -p 30000:30000/tcp \
        -v $PWD/data:/var/lib/minetest:rw \
        myserver:latest \
        minetest-wrapper.sh --config /var/lib/minetest/minetest.conf

