#!/usr/bin/env bash
set -Eeuox pipefail

# https://medium.com/@gchudnov/trapping-signals-in-docker-containers-7a57fdda7d86

echo "Mount /data/db."
smbnetfs /data/db -o config=/etc/smbnetfs.conf \
    -o uid=$(id -u mongodb) -o gid=$(id -g mongodb) \
    -o umask=0077

pid=0

# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi

  #Cleanup
  echo "Unmount /data/db."
  fusermount -u /data/db

  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; term_handler' SIGTERM

# run application
docker-entrypoint.sh "${@}" &
pid="$!"

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done

# http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html
# When Bash receives a signal for which a trap has been set while waiting for a
# command to complete, the trap will not be executed until the command
# completes. When Bash is waiting for an asynchronous command via the wait
# built-in, the reception of a signal for which a trap has been set will cause
# the wait built-in to return immediately with an exit status greater than 128,
# immediately after which the trap is executed.