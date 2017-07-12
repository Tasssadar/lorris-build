#!/bin/bash
set -eu

DOCKER_ROOT="/home/tassadar/dockertest/win32"
IMG_NAME="lorris-build_windows-i386"

docker build -t "${IMG_NAME}" "${DOCKER_ROOT}"
docker run -t -v "${DOCKER_ROOT}/lorris-release:/lorris-release" "${IMG_NAME}"
