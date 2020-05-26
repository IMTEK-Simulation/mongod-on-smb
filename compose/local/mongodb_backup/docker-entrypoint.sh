#!/usr/bin/env bash
#
# mongodb_backup/docker-entrypoint.sh
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
set -Eeuox pipefail

echo "Running entrypoint as $(whoami), uid=$(id -u), gid=$(id -g)."

echo ""
echo "Current mounts:"
mount
echo ""
echo "Content at '/data/backup':"
ls -lha /data/backup

echo ""
echo "Process upstream entrypoint."

# Trapping of SIGTERM for clean shutdown
# https://medium.com/@gchudnov/trapping-signals-in-docker-containers-7a57fdda7d86
pid=0

# SIGTERM-handler
term_handler() {
  #Cleanup
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  echo "Shut down gracefully."
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, execute the specified handler
trap 'term_handler' SIGTERM

# run application
${@} &
pid="$!"
wait "$pid"
ret="$?"
echo "${@} ended with return code ${ret}".
exit "${ret}"

# http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html
# When Bash receives a signal for which a trap has been set while waiting for a
# command to complete, the trap will not be executed until the command
# completes. When Bash is waiting for an asynchronous command via the wait
# built-in, the reception of a signal for which a trap has been set will cause
# the wait built-in to return immediately with an exit status greater than 128,
# immediately after which the trap is executed.