ARG DIST_TAG=trusty
FROM i386/ubuntu:$DIST_TAG

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y g++ make libudev-dev python2.7-dev qt5-default qttools5-dev qtscript5-dev pkg-config git dpkg && \
    apt-get clean

ADD /build /build
WORKDIR /build

ENV THREADS=3

ARG DIST_TAG
ENV DIST_TAG $DIST_TAG

ENV DIST_VER=1

ENTRYPOINT echo "BUILDING: ${DIST_TAG}+${DIST_VER} i386" && \
    git clone --depth=1 --recursive https://github.com/Tasssadar/Lorris.git && \
    cd Lorris && \
    (([ "$DIST_TAG" != "trusty" ]) || sed -i 's/CONFIG += opengl/#CONFIG += opengl/' config.pri) && \
    qmake CONFIG+=release QMAKE_CXXFLAGS+="-march=pentium4 -mfpmath=sse -msse2" QMAKE_CFLAGS+="-march=pentium4 -mfpmath=sse -msse2" -r && \
    make -j$THREADS && \
    cd .. && python2.7 ./lorris_deb.py Lorris /apt-pool i386 $DIST_TAG $DIST_VER

VOLUME /apt-pool
