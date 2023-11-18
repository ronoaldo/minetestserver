# Build stage
FROM debian:bookworm-slim AS builder

# Build-time arguments
ARG MINETEST_VERSION=master
ARG MINETEST_GAME_VERSION=master
ARG MINETEST_IRRLICHT_VERSION=master
ARG MINETOOLS_VERSION=v0.2.2
# Using a specific and newer LuaJIT commit to fix several ARM issues
# and crashes. This commit uses the unrelease v2.1 branch.
ARG LUAJIT_VERSION=505e2c03de35e2718eef0d2d3660712e06dadf1f

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
    git clone --depth=1 -b ${MINETEST_VERSION} \
        https://github.com/minetest/minetest.git \
        /usr/src/minetest &&\
    rm -rf /usr/src/minetest/.git
RUN git clone --depth=1 -b ${MINETEST_GAME_VERSION} \
        https://github.com/minetest/minetest_game.git \
        /usr/src/minetest/games/minetest_game
RUN git clone --depth=1 -b ${MINETEST_IRRLICHT_VERSION} \
        https://github.com/minetest/irrlicht \
        /usr/src/minetest/lib/irrlichtmt
RUN git clone \
        https://github.com/LuaJIT/LuaJIT.git \
        /usr/src/luajit &&\
    git -C /usr/src/luajit checkout ${LUAJIT_VERSION}

# Install Contentdb CLI
RUN echo "Building for arch $(uname -m)" &&\
    case $(uname -m) in \
        x86_64)  export ARCH=amd64 ;; \
        aarch64) export ARCH=arm64 ;; \
        *) echo "Unsupported arch $(uname -m)" ; exit 1 ;; \
    esac &&\
    curl -SsL --fail \
        https://github.com/ronoaldo/minetools/releases/download/${MINETOOLS_VERSION}/contentdb-linux-${ARCH}.zip > /tmp/minetools.zip &&\
        cd /tmp/ && unzip minetools.zip && mv dist/contentdb /usr/bin &&\
        rm /tmp/minetools.zip

# Build LuaJIT
WORKDIR /usr/src/luajit
RUN sed -e 's/PREREL=.*/PREREL=-beta4-mercurio/g' -i Makefile
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
RUN adduser --system --uid 30000 --group --home /var/lib/minetest minetest &&\
    chown -R minetest:minetest /var/lib/minetest

# Copy files and folders
COPY --from=builder /usr/share/doc/minetest/minetest.conf.example /etc/minetest/minetest.conf
COPY --from=builder /usr/share/minetest     /usr/share/minetest
COPY --from=builder /usr/bin/minetestserver /usr/bin
COPY --from=builder /usr/bin/contentdb      /usr/bin
COPY --from=builder /opt/luajit/usr/        /usr/
ADD minetest-wrapper.sh /usr/bin

WORKDIR /var/lib/minetest
USER minetest
EXPOSE 30000/udp 30000/tcp
CMD ["/usr/bin/minetest-wrapper.sh", "--config", "/etc/minetest/minetest.conf"]
