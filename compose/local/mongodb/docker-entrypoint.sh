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

echo ""
echo "Content at '/data/db':"
su -c 'ls -lha /data/db' mongodb
echo ""
echo "Current mounts:"

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
exit "${ret}"

# http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html
# When Bash receives a signal for which a trap has been set while waiting for a
# command to complete, the trap will not be executed until the command
# completes. When Bash is waiting for an asynchronous command via the wait
# built-in, the reception of a signal for which a trap has been set will cause
# the wait built-in to return immediately with an exit status greater than 128,
# immediately after which the trap is executed.