ARG DIST_TAG=trusty
FROM ubuntu:$DIST_TAG

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y g++ make libudev-dev python2.7-dev qtbase5-dev qtchooser qttools5-dev qtscript5-dev pkg-config git dpkg && \
    (apt-get install -y qt5-default || true) && \
    apt-get clean

ADD /build /build
WORKDIR /build

ENV THREADS=3

ARG DIST_TAG
ENV DIST_TAG $DIST_TAG

ENV DIST_VER=1

ENV CFLAGS="-march=nehalem -mtune=haswell -O3 -funsafe-math-optimizations -fexcess-precision=fast -fno-math-errno -flto"

ENTRYPOINT echo "BUILDING: ${DIST_TAG}+${DIST_VER} amd64" && \
    git clone --depth=1 --recursive https://github.com/Tasssadar/Lorris.git && \
    cd Lorris && \
    ([ "$DIST_TAG" != "xenial" ]) || export CFLAGS="-O3" && \
    qmake -r CONFIG+=release \
        QMAKE_CXXFLAGS_RELEASE-="-O2" QMAKE_CFLAGS_RELEASE-="-O2" \
        QMAKE_CXXFLAGS+="$CFLAGS" \
          QMAKE_CFLAGS+="$CFLAGS" \
          QMAKE_LFLAGS+="$CFLAGS"  && \
    make -j$THREADS && \
    cd .. && python2.7 ./lorris_deb.py Lorris /apt-pool amd64 $DIST_TAG $DIST_VER

VOLUME /apt-pool
