#!/bin/bash
set -eu

WIN_USER="tassadar"

if [ "$(whoami)" != "root" ]; then
    echo
    echo "ERROR: Run this script with sudo, it needs the rights to be able to"
    echo "copy & move files from the docker images"
    echo
    exit 1
fi

cd win
sudo -u "$WIN_USER" ./build.sh
cd ..

cd ubuntu
./build.sh
cd ..