#!/usr/bin/env bash
#
# mongodb_on_smb/docker-entrypoint.sh
#
# Copyright (C) 2020, IMTEK Simulation
# Author: Johannes Hoermann, johannes.hoermann@imtek.uni-freiburg.de
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#
# Summary:
#
# This entrypoint wraps around the upstream image's docker-entrypoint.sh
#Ãand takes care of propery providing an smb share the actual mongodb
# resides on.
#
set -Eeuox pipefail

echo "Running entrypoint as $(whoami), uid=$(id -u), gid=$(id -g)."

mkdir -p /mnt/smb
chown mongodb:mongodb /mnt/smb

# smbnetfs looks for a user configuration within $HOME/.smb
# and will display a warning if not found.
# Instead, we specify /etc/smbnetfs.conf. Within that file,
# smbnetfs looks for information on how to authenticate for specific
# shares. The option smb_query_browser=false disables automized
# scanning of the local SMB network.
# This entrypoint script runs as root:root. To make the mounted
# share available to user 'mongodb', we specify explicitly
# uid, gid and 'allow_other'.
# NOTE: 'direct_io' possibly obsolete, not teste without.
echo "Mount /mnt/smb."
smbnetfs /mnt/smb -o config=/etc/smbnetfs.conf \
    -o smbnetfs_debug=10 -o log_file=/var/log/smbnetfs.log \
    -o smb_debug_level=10 -o smb_query_browsers=false \
    -o uid=$(id -u mongodb) -o gid=$(id -g mongodb) \
    -o umask=0077 -o direct_io -o allow_other

# smbnetfs makes all smb shares available in a POSIX-standard manner
# within a single mount point. With the above configuration,
# a share 'smb://fqdn.of.smb.host/share' or '\\fqdn.of.smb.host\share' will be
# accessible via '/mnt/smb/fqdn.of.smb.host/share'. Any sub-folders within the
# share are postpended.
echo "Content at '$(cat /run/secrets/smbnetfs-smbshare-mountpoint)':"
ls -lha "$(cat /run/secrets/smbnetfs-smbshare-mountpoint)"
echo ""

# /data/db designated as persistant volume in parent image, unmount...
umount /data/db

# ... and replace with smb share using bindfs.
# NOTE: ownership changes here might not be necessary, just in case.
# NOTE: might not be necessary, but just in case we apply the same
# ownership and permission  options as for the underlying smb mount
chown mongodb:mongodb /data/db
echo "Bind '/data/db' -> '$(cat /run/secrets/smbnetfs-smbshare-mountpoint)'"
bindfs \
    -o uid=$(id -u mongodb) -o gid=$(id -g mongodb) \
    -o umask=0077 -o direct_io -o allow_other \
    "$(cat /run/secrets/smbnetfs-smbshare-mountpoint)" /data/db

echo ""
echo "Content at '/data/db':"
ls -lha /data/db
echo ""
echo "Current mounts:"
mount

# The following files are not part of this image. We expect them to be
# provided at runtime, i.e. via an appropriate entry within
# the evoking user's $HOME/.config/containers/mounts.conf.
# Set correct rights for secrets:
chown mongodb:mongodb /run/secrets/mongodb/password
chown mongodb:mongodb /run/secrets/mongodb/username
chown mongodb:mongodb /run/secrets/mongodb/tls_key_cert.pem
chown mongodb:mongodb /run/secrets/rootCA.pem

echo ""
echo "Process upstream entrypoint."


# Trapping of SIGTERM for clean unmounting of smb share
# afte mongod shutdown following
# https://medium.com/@gchudnov/trapping-signals-in-docker-containers-7a57fdda7d86
pid=0

# SIGTERM-handler
term_handler() {
  #Cleanup
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  echo "Unmount smb share gracefully."
  fusermount -u /data/db
  fusermount -u /mnt/smb
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, execute the specified handler
trap 'term_handler' SIGTERM

# run application
docker-entrypoint.sh "${@}" &
pid="$!"
wait "$pid"
ret="$?"
echo "docker-entrypoint ${@} ended with return code ${ret}".
echo "Unmount smb share gracefully."
fusermount -u /data/db
fusermount -u /mnt/smb
exit "${ret}"

# http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html
# When Bash receives a signal for which a trap has been set while waiting for a
# command to complete, the trap will not be executed until the command
# completes. When Bash is waiting for an asynchronous command via the wait
# built-in, the reception of a signal for which a trap has been set will cause
# the wait built-in to return immediately with an exit status greater than 128,
# immediately after which the trap is executed.