#!/usr/bin/env python

import sys
import tempfile
import shutil
import os
import subprocess

BIN_PATH="bin/release/lorris"
PREFIX="usr"

def get_version(root):
    with open(os.path.join(root, "src", "revision.h"), "r") as f:
        tag = "REVISION "
        for l in f:
            idx = l.find(tag)
            if idx != -1:
                return int(l[idx+len(tag):])
    raise Exception("Failed to parse revision.h!")

def get_qt_deps(tag):
    libs = [ "libqt5script5", "libqt5network5", "libqt5widgets5", "libqt5gui5", "libqt5core5a" ]
    minver = "5.4.0" if tag != "trusty" else "5.2.0"
    for i in range(len(libs)):
        libs[i] = "%s (>= %s)" % (libs[i], minver)
    return ", ".join(libs)

if __name__ == "__main__":
    if len(sys.argv) < 6:
        print "Usage: %s LORRIS_ROOT DEST_DIR ARCH TAG DIST_VER" % sys.argv[0]
        sys.exit(1)
    
    root = sys.argv[1]
    destdir = sys.argv[2]
    arch = sys.argv[3]
    tag = sys.argv[4]
    dist_ver = int(sys.argv[5])
    tmpdir = tempfile.mkdtemp()

    if arch != "i386" and arch != "amd64":
        print "Invalid arch: %s" % arch
        sys.exit(1)

    if not os.path.exists(destdir):
        print "Destdir %s does not exist!" % destdir
        sys.exit(1)

    destdir = os.path.join(destdir, "dists", tag)
    if not os.path.exists(destdir):
        os.makedirs(destdir)

    try:
        bin_path = os.path.join(tmpdir, PREFIX, "bin")
        os.makedirs(bin_path)
        shutil.copy(os.path.join(root, BIN_PATH), bin_path)

        trans_path = os.path.join(tmpdir, PREFIX, "share", "lorris") 
        os.makedirs(trans_path)
        shutil.copy(os.path.join(root, "translations", "Lorris.cs_CZ.qm"), trans_path)

        desktop_path = os.path.join(tmpdir, PREFIX, "share", "applications")
        os.makedirs(desktop_path)
        shutil.copy("lorris.desktop", desktop_path)

        pixmap_path = os.path.join(tmpdir, PREFIX, "share", "pixmaps")
        os.makedirs(pixmap_path)
        shutil.copy("lorris.png", pixmap_path)

        qtdeps = get_qt_deps(tag)
        version = "0.%d-%s+%d" % (get_version(root), tag, dist_ver)
        control_dir = os.path.join(tmpdir, "DEBIAN")
        control = os.path.join(control_dir, "control")
        os.makedirs(control_dir)
        with open(control, "w") as f:
            f.write("""Package: lorris
Version: %s
Section: base
Priority: optional
Architecture: %s
Depends: libpython2.7, libudev1, %s
Maintainer: Vojtech Bocek <vbocek@gmail.com>
Description: Lorris Toolbox
  GUI tool written in Qt which aims to be used when dealing with embedded devices, robots
  and similar applications where you need to do something with data.
""" % (version, arch, qtdeps))

        subprocess.check_call(["dpkg-deb", "--build", tmpdir,
            os.path.join(destdir, "lorris_%s_%s.deb" % (version, arch)) ]) 
    finally:
        shutil.rmtree(tmpdir)
