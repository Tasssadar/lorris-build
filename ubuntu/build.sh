#!/bin/bash
set -eu
#set -x

ARCHS="amd64 i386"
DISTS="trusty xenial artful"
STABLE_DIST="xenial"
APT_ROOT="/opt/lorris-apt/ubuntu"
TMP_POOL="${APT_ROOT}/tmp-pool"
REAL_POOL="${APT_ROOT}/pool"
DOCKER_ROOT="/home/tassadar/dockertest/ubuntu"
GPG_KEY_NAME="tasemnice-apt"

if [ "$(whoami)" != "root" ]; then
    echo
    echo "ERROR: Run this script with sudo, it needs the rights to be able to"
    echo "copy & move files from the docker images"
    echo
    exit 1
fi

build=true
genapt=true
ignoretmp=false
ver="1"
while [ $# -ge 1 ]; do
    case "$1" in
    --nobuild)
        build=false
        ;;
    --noapt)
        genapt=false
        ;;
    --ignoretmp)
        ignoretmp=true
        ;;
    --ver=*)
        ver="${1#--ver=}"
        ;;
    *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
    shift
done

if ! [ -f "${DOCKER_ROOT}/apt/keys/pass.gpg" ]; then
    echo "The gpg passphrase file ${DOCKER_ROOT}/apt/pass.gpg does not exists."
    exit 1
fi

if $build; then
    if ! $ignoretmp && [ -d "${TMP_POOL}" ]; then
        echo "Temp pool directory (${TMP_POOL}) already exists!"
        exit 1
    fi

    mkdir -p "${TMP_POOL}"
    for arch in $ARCHS; do
        for dist in $DISTS; do
            echo
            echo "BUILDING ${dist}-${arch}"
            echo

            img="lorris-build_${dist}-${arch}"
            cp -a "${DOCKER_ROOT}/build" "${DOCKER_ROOT}/docker-${arch}/"
            docker build --build-arg DIST_TAG=$dist -t "$img" "${DOCKER_ROOT}/docker-${arch}"
            docker run -t -e DIST_VER=${ver} -v "${TMP_POOL}:/apt-pool" "$img"

            if [ -d "${DOCKER_ROOT}/extra/${dist}" ]; then
                cp -a $(find "${DOCKER_ROOT}/extra/${dist}" -name *_${arch}.deb) "${TMP_POOL}/dists/${dist}/" || true
            fi
        done
    done

    rm -rf "${TMP_POOL}/dists/stable"
    cp -a "${TMP_POOL}/dists/${STABLE_DIST}" "${TMP_POOL}/dists/stable"
fi

if $genapt; then
    if [ -d "${TMP_POOL}" ]; then
        if [ "$(find ${TMP_POOL} -type f | wc -l)" = "0" ]; then
            echo "No files in ${TMP_POOL}"
            exit 1
        fi 
        rm -rf "${APT_ROOT}/pool-bak"
        mv "${REAL_POOL}" "${APT_ROOT}/pool-bak"
        mv "${TMP_POOL}" "${REAL_POOL}"
    fi

    DISTS="$DISTS stable"

    for arch in $ARCHS; do
        for dist in $DISTS; do
            mkdir -p "${APT_ROOT}/dists/${dist}/main/binary-${arch}"
        done
    done

    rm -rf "${APT_ROOT}/cache"
    mkdir -p "${APT_ROOT}/cache"
    apt-ftparchive generate "${DOCKER_ROOT}/apt/ftparchive.conf"
    for dist in $DISTS; do
        if ! [ -f "${DOCKER_ROOT}/apt/${dist}.conf" ]; then
            continue
        fi

        rel="${APT_ROOT}/dists/${dist}/Release"
        inrel="${APT_ROOT}/dists/${dist}/InRelease"
        apt-ftparchive -c "${DOCKER_ROOT}/apt/${dist}.conf" release "${APT_ROOT}/dists/${dist}" > "$rel"
        cat "${DOCKER_ROOT}/apt/keys/pass.gpg" | gpg --yes --batch --passphrase-fd 0 --digest-algo SHA512 -abs -u $GPG_KEY_NAME -o "${rel}.gpg" "$rel"
        cat "${DOCKER_ROOT}/apt/keys/pass.gpg" | gpg --yes --batch --passphrase-fd 0 --digest-algo SHA512 --clearsign -u $GPG_KEY_NAME --output "$inrel" "$rel"
    done

    rm -rf "${APT_ROOT}/cache"
fi
