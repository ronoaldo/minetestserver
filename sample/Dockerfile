# Use the default stable 5.x version
ARG BASE_IMAGE=ghcr.io/ronoaldo/luantiserver:stable-5
FROM ${BASE_IMAGE}

# Install mods from ContentDB
WORKDIR /usr/share/luanti
USER root
RUN contentdb install TenPlus1/ethereal
RUN contentdb install stu/3d_armor

# Prepare the server to run
COPY luanti.conf /etc/luanti/luanti.conf
WORKDIR /var/lib/luanti
USER luanti
