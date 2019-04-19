#!/bin/bash
set -eu

DOCKER_ROOT="/home/tassadar/lorris-build/win32"
IMG_NAME="lorris-build_windows-i386"
DESTDIR="${DOCKER_ROOT}/lorris-release"
KEYS="${DOCKER_ROOT}/keys"
WWW="/www/lorris"
ADDR="http://tasemnice.eu/lorris"

build=true
release=true
while [ $# -ge 1 ]; do
    case "$1" in
    --nobuild)
        build=false
        ;;
    --norelease)
        release=false
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
    shift
done

if $build; then
    rm -f "${DESTDIR}/Lorris.zip" "${DESTDIR}/version.txt"
    docker build -t "${IMG_NAME}" "${DOCKER_ROOT}"
    docker run -t -v "${DESTDIR}:/lorris-release" "${IMG_NAME}"
fi

if $release; then
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
fi
