FROM ghcr.io/ronoaldo/minetestserver:stable-5

# Install mods from ContentDB
WORKDIR /usr/share/minetest
USER root
RUN contentdb install TenPlus1/ethereal
RUN contentdb install stu/3d_armor

# Prepare the server to run
COPY minetest.conf /etc/minetest/minetest.conf
WORKDIR /var/lib/minetest
USER minetest
