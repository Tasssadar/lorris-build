#!/bin/bash
set -eu

DOCKER_ROOT="/home/tassadar/lorris-build/win32"
IMG_NAME="lorris-build_windows"
DESTDIR="${DOCKER_ROOT}/lorris-release"
KEYS="${DOCKER_ROOT}/keys"
WWW="/www/lorris"
ADDR="http://tasemnice.eu/lorris"

build32=true
build64=true
release32=true
release64=true
while [ $# -ge 1 ]; do
    case "$1" in
    --nobuild)
        build32=false
        build64=false
        ;;
    --norelease)
        release32=false
        release64=false
        ;;
    --nobuild32)
        build32=false
        ;;
    --norelease32)
        release32=false
        ;;
    --nobuild64)
        build64=false
        ;;
    --norelease64)
        release64=false
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
    shift
done

build() {
    sfx="$1"
    rm -f "${DESTDIR}${sfx}/Lorris.zip" "${DESTDIR}${sfx}/version.txt"
    docker build -t "${IMG_NAME}${sfx}" -f Dockerfile.${sfx} "${DOCKER_ROOT}"
    docker run -t -v "${DESTDIR}${sfx}:/lorris-release" "${IMG_NAME}${sfx}"
}

release() {
    sfx="$1"
    DESTDIR="${DESTDIR}${sfx}"
    ADDR="${ADDR}${sfx}"
    WWW="${WWW}${sfx}"

    if ! [ -f "${DESTDIR}/Lorris.zip" ]; then
        echo "${DESTDIR}/Lorris.zip not found!"
        exit 1
    fi

    if ! [ -f "${DESTDIR}/version.txt" ]; then
        echo "${DESTDIR}/version.txt not found!"
        exit 1
    fi

    version="$(cat ${DESTDIR}/version.txt)"

    echo "Releasing version $version"

    cp "${DESTDIR}/Lorris.zip" "${WWW}/Lorris.zip"
    hash="$(sha256sum ${WWW}/Lorris.zip | head -c64)"

    mkdir -p "${WWW}/archive"
    cp "${DESTDIR}/Lorris.zip" "${WWW}/archive/Lorris-v${version}.zip"
    echo "${hash}  Lorris-v${version}.zip" >> "${WWW}/archive/sha256sum.txt"

    "${KEYS}/signtool" sign "${WWW}/Lorris.zip" "${KEYS}/key.priv" "${WWW}/Lorris.zip.sig"

    echo "release $version ${ADDR}/Lorris.zip $hash" > "${WWW}/updater_manifest.txt"
    echo "dev $version ${ADDR}/Lorris.zip $hash" >> "${WWW}/updater_manifest.txt"
    echo "changelog1 ${ADDR}/changelog.txt" >> "${WWW}/updater_manifest.txt"
    echo "changelog2 ${ADDR}/changelog.txt" >> "${WWW}/updater_manifest.txt"

    "${KEYS}/signtool" sign "${WWW}/updater_manifest.txt" "${KEYS}/key.priv" "${WWW}/updater_manifest.txt.sig"
}

if $build32; then
    build 32
fi

if $build64; then
    build 64
fi

if $release32; then
    (release 32)
fi

if $release64; then
    (release 64)
fi
