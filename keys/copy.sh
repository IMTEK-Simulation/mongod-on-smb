#!/bin/bash
set -x
# this snippet avoids using rsync

# first run generate.sh, then copy.sh DEST to move relevant files (without rootCA.key) to DEST
DEST="${1%%/}"
# set restrictive permissions on local files
chmod -R go-rwx .

# create target directory hierarchy
find . -type f -name '*.pem' -printf "%h\n" | sort -u | sed -E 's|^\./||' | xargs -n 1 -I {} echo "${DEST}/{}" | xargs -n 1 mkdir -p
# printf "%h\n" prints only the file's leading directory name
# http://man7.org/linux/man-pages/man1/find.1.html
# sed command removes leading curdir '.' character followed by path separator '/' from directory names

# set restrictive permissions on target directory hierarchy
chmod -R go-rwx "${DEST}"

# copy all *.pem key and certificate files to target hierarchy
find . -type f -name '*.pem' | xargs -n 1 -I {} cp "{}" "${DEST}/{}"