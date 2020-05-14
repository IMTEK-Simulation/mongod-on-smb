#!/bin/bash
set -Eeuo pipefail
mount /data/db
exec /usr/local/bin/docker-entrypoint.sh "$@"