FROM ghcr.io/ronoaldo/minetestserver:stable-5
USER root
RUN  cd /usr/share/minetest &&\
        contentdb install TenPlus1/ethereal
COPY minetest.conf /etc/minetest/minetest.conf
USER minetest
