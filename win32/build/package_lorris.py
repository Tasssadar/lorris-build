#!/usr/bin/env python

import sys
import os
import shutil
import subprocess

BIN_PATH="bin/release/Lorris.exe"
DLL_DUMP="-w64-mingw32-objdump  -x \"%s\" | grep -o 'DLL Name: [a-zA-Z0-9\\._+-]*'"
STRIP="-w64-mingw32-strip  %s"
QT_HOME=""

def init_search_paths_tools(lorris_root):
    global DLL_DUMP
    global STRIP
    global QT_HOME

    res = {
        "%s/dep/pythonqt" % lorris_root: None,
        "%s/dep/qwt/lib" % lorris_root: None,
        "%s/dep/qscintilla2/lib" % lorris_root: None,
    }

    build = "x86_64" if subprocess.call("file %s/%s | grep -q x86-64" % (lorris_root, BIN_PATH), shell=True) == 0 else "i686"
    if build == "x86_64":
        QT_HOME="/usr/local/qt64"
        res["%s/dep/python2.7/lib64" % lorris_root] = None
        res["/usr/lib/gcc/x86_64-w64-mingw32/5.3-win32"] = None
    else:
        QT_HOME="/usr/local/qt32"
        res["%s/dep/python2.7/lib" % lorris_root] = None
        res["/usr/lib/gcc/i686-w64-mingw32/5.3-win32"] = None
    res["%s/bin" % QT_HOME] = None
    res["%s/plugins/platforms" % QT_HOME] = None
    DLL_DUMP = build + DLL_DUMP
    STRIP = build + STRIP

    print "Build: %s, Qt: %s" % (build, QT_HOME)
    print "Search paths:"
    for path in res:
        print "  %s" % os.path.abspath(path)
        res[path] = os.listdir(path)
    return res

def copy_dep(dep_name, dest, search_paths, copied):
    for sp in search_paths:
        for f in search_paths[sp]:
            if f == dep_name:
                copy_bin_with_deps(os.path.join(sp, f), dest, search_paths, copied)
                return True
    return False

def copy_bin_with_deps(bin_path, dest, search_paths, copied):
    bin_path = os.path.abspath(bin_path)
    if bin_path in copied:
        return

    copied[bin_path] = True

    print "  %s" % bin_path
    shutil.copy(bin_path, dest)
    subprocess.check_call(STRIP % (os.path.join(dest, os.path.basename(bin_path))), shell=True)
    out = subprocess.check_output(DLL_DUMP % bin_path, shell=True)

    for line in iter(out.splitlines()):
        dllname = line[len("DLL Name: "):]
        copy_dep(dllname, dest, search_paths, copied)

def get_version(root):
    with open(os.path.join(root, "src", "revision.h"), "r") as f:
        tag = "REVISION "
        for l in f:
            idx = l.find(tag)
            if idx != -1:
                return int(l[idx+len(tag):])
    raise Exception("Failed to parse revision.h!")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print "Usage: %s LORRIS_ROOT DEST_DIR" % sys.argv[0]
        sys.exit(1)

    lorris_root = sys.argv[1]
    dest_dir = sys.argv[2]
    subdirs = [ "", "platforms", "translations" ]
    for d in subdirs:
        try:
            os.makedirs(os.path.join(dest_dir, d))
        except:
            pass

    copied = {}
    search_paths = init_search_paths_tools(lorris_root)

    print "Binaries:"
    copy_bin_with_deps(os.path.join(lorris_root, BIN_PATH), dest_dir, search_paths, copied)
    copy_dep("qwindows.dll", dest_dir + "/platforms", search_paths, copied)

    shutil.copy("%s/translations/Lorris.cs_CZ.qm" % lorris_root, dest_dir + "/translations")
    shutil.copy("%s/translations/qt_cs.qm" % QT_HOME, dest_dir + "/translations")
    shutil.copy("%s/translations/qtbase_cs.qm" % QT_HOME, dest_dir + "/translations")
    shutil.copy("updater.exe", dest_dir + "/")

    with open("%s/version.txt" % dest_dir, "w") as f:
        f.write("%d\n" % get_version(lorris_root))
