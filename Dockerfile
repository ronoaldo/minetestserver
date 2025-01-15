# Build stage
FROM debian:bookworm-slim AS builder

# Build-time arguments - defaults to dev build of more recent version
ARG LUANTI_VERSION=master
ARG MINETEST_GAME_VERSION=master
# LuaJIT rolling stable branch is v2.1
ARG LUAJIT_VERSION=v2.1

ARG MINETOOLS_VERSION=v0.2.2
ENV MINETOOLS_DL_URL=https://github.com/ronoaldo/minetools/releases/download

# Install all build-dependencies
RUN apt-get update &&\
    apt-get install build-essential cmake gettext libbz2-dev libcurl4-gnutls-dev \
        libfreetype6-dev libglu1-mesa-dev libgmp-dev \
        libjpeg-dev libjsoncpp-dev libleveldb-dev \
        libogg-dev libopenal-dev libpng-dev libpq-dev libspatialindex-dev \
        libsqlite3-dev libvorbis-dev libx11-dev libxxf86vm-dev libzstd-dev \
        postgresql-server-dev-all zlib1g-dev git unzip ninja-build -yq &&\
    apt-get clean

# Fetch source
RUN mkdir -p /usr/src &&\
    git clone -b ${LUANTI_VERSION} \
        https://github.com/minetest/minetest \
        /usr/src/minetest &&\
    rm -rf /usr/src/minetest/.git
RUN git clone https://github.com/minetest/minetest_game \
        /usr/src/minetest/games/minetest_game &&\
    git -C /usr/src/minetest/games/minetest_game checkout ${MINETEST_GAME_VERSION}
RUN git clone \
        https://github.com/LuaJIT/LuaJIT \
        /usr/src/luajit &&\
    git -C /usr/src/luajit checkout ${LUAJIT_VERSION}

# Apply patches
ADD patches /usr/src/patches
RUN cd /usr/src/minetest ;\
    ls -1 /usr/src/patches/${LUANTI_VERSION}-*.patch | while read file ; do \
        patch -p1 < $file ; \
    done

# Install Contentdb CLI
RUN echo "Building for arch $(uname -m)" &&\
    case $(uname -m) in \
        x86_64)  export ARCH=amd64 ;; \
        aarch64) export ARCH=arm64 ;; \
        *) echo "Unsupported arch $(uname -m)" ; exit 1 ;; \
    esac &&\
    curl -SsL --fail \
        ${MINETOOLS_DL_URL}/${MINETOOLS_VERSION}/contentdb-linux-${ARCH}.zip > /tmp/minetools.zip &&\
        cd /tmp/ && unzip minetools.zip && mv dist/contentdb /usr/bin &&\
        rm /tmp/minetools.zip

# Build LuaJIT
WORKDIR /usr/src/luajit
RUN sed -e 's/PREREL=.*/PREREL=-rolling/g' -i Makefile
RUN make PREFIX=/usr &&\
    make install PREFIX=/usr &&\
    make install PREFIX=/usr DESTDIR=/opt/luajit

# Build server
WORKDIR /tmp/build
RUN cmake -G Ninja /usr/src/minetest \
        -DENABLE_POSTGRESQL=TRUE \
        -DPostgreSQL_TYPE_INCLUDE_DIR=/usr/include/postgresql \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=RelWithDebug \
        -DBUILD_SERVER=TRUE \
        -DBUILD_CLIENT=FALSE \
        -DBUILD_UNITTESTS=FALSE \
        -DVERSION_EXTRA=unofficial &&\
    ninja -j$(nproc) &&\
    ninja install

# Bundle only the runtime dependencies
FROM debian:bookworm-slim AS runtime
RUN apt-get update &&\
    apt-get install libcurl3-gnutls libgcc-s1 libgmp10 libjsoncpp25 \
        libleveldb1d libncursesw6 libpq5 \
        libspatialindex6 libsqlite3-0 libstdc++6 libtinfo6 zlib1g libzstd1 \
        adduser git -yq &&\
    apt-get clean
# Creates a user to run the server as, with a home dir that can be mounted
# as a volume
RUN adduser --system --uid 30000 --group --home /var/lib/luanti luanti &&\
    chown -R luanti:luanti /var/lib/luanti

# Copy files and folders
COPY --from=builder /usr/share/doc/luanti/minetest.conf.example /etc/luanti/luanti.conf
COPY --from=builder /usr/share/luanti       /usr/share/luanti
COPY --from=builder /usr/src/minetest/games /usr/share/luanti/games
COPY --from=builder /usr/bin/luantiserver   /usr/bin
COPY --from=builder /usr/bin/contentdb      /usr/bin
COPY --from=builder /opt/luajit/usr/        /usr/
ADD luanti-wrapper.sh /usr/bin

# Add symlinks (minetest -> luanti) to easy the upgrade after upstream rename
RUN ln -s /usr/share/luanti /usr/share/minetest &&\
    ln -s /etc/luanti /etc/minetest &&\
    ln -s /etc/luanti/luanti.conf /etc/luanti/minetest.conf &&\
    ln -s /usr/bin/luanti-wrapper.sh /usr/bin/minetest-wrapper.sh

WORKDIR /var/lib/luanti
USER luanti 
EXPOSE 30000/udp 30000/tcp
CMD ["/usr/bin/luanti-wrapper.sh", "--config", "/etc/luanti/luanti.conf", "--gameid", "minetest"]
