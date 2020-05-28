#!/bin/bash
# dump everything
outdir="/data/backup/DB_FULL_DUMP/$(date +%Y%m%d_%s)"
dry_run=false

usage() {
  echo -n "

Usage: $(basename "$0") [OPTIONS]

  Dump everything to '--outdir OUTDIR' (default: '${outdir}') using 'mongodump'.

Options:

  -h, --help
  -n, --dry-run     Show databases in filter, but don't actually dump.
  -o, --outdir      Output directory.
"
}

args=$(getopt -n "$0" -l "help,dry-run,outdir:" -o "hno:" -- "$@")
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$args"

while true; do
  case "$1" in
    -h | --help ) usage ; exit 0 ;;
    -n | --dry-run ) dry_run=true; shift;;
    -o | --outdir ) outdir="$2"; shift ; shift;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done
source init_static_params.sh

if [ "${dry_run}" == false ]; then
    mkdir -p -v "${outdir}"
fi
log $LOG_MESSAGE_INFO "[INFO] Output directory: '$(readlink -f ${outdir})'"
log $LOG_MESSAGE_INFO "[INFO] Current content:"
ls -lha "${outdir}"

if [ "${dry_run}" == false ]; then
    mongodump ${SSL_OPTS} ${AUTH_OPTS} --verbose --oplog --gzip --out "${outdir}"
fi
