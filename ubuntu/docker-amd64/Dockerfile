ARG DIST_TAG=trusty
FROM ubuntu:$DIST_TAG

RUN apt-get update && \
    apt-get install -y g++ make libudev-dev python2.7-dev qt5-default qttools5-dev qtscript5-dev pkg-config git dpkg && \
    apt-get clean

ADD /build /build
WORKDIR /build

ENV THREADS=2

ARG DIST_TAG
ENV DIST_TAG $DIST_TAG

ENTRYPOINT git clone --depth=1 --recursive https://github.com/Tasssadar/Lorris.git && \
    cd Lorris && \
    (([ "$DIST_TAG" != "trusty" ]) || sed -i 's/CONFIG += opengl/#CONFIG += opengl/' config.pri) && \
    qmake CONFIG+=release -r && \
    make -j$THREADS && \
    cd .. && python2.7 ./lorris_deb.py Lorris /apt-pool amd64 $DIST_TAG

VOLUME /apt-pool