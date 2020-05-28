#!/bin/bash
# dump all databases macthing a certain regular expression
db_regex='^fireworks-'
outdir="/data/backup/DBDUMP/$(date +%Y%m%d)"
dry_run=false

usage() {
  echo -n "

Usage: $(basename "$0") [OPTIONS]

  Dumps databases with name matching '--regex REGEX' (default: '${db_regex}')
  to '--outdir OUTDIR' (default: '${outdir}') using 'mongodump'.

Options:

  -h, --help
  -n, --dry-run     Show databases in filter, but don't actually dump.
  -r, --regex       Regular expression filter on database names.
  -o, --outdir      Output directory.
"
}

args=$(getopt -n "$0" -l "help,dry-run,regex:,outdir:" -o "hnr:o:" -- "$@")
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$args"

while true; do
  case "$1" in
    -h | --help ) usage ; exit 0 ;;
    -n | --dry-run ) dry_run=true; shift;;
    -r | --regex ) db_regex="$2"; shift ; shift;;
    -o | --outdir ) outdir="$2"; shift ; shift;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

echo "Regex filter:     '${db_regex}'"
if [ "${dry_run}" == false ]; then
    mkdir -p "${outdir}"
fi
echo "Output directory: '$(readlink -f ${outdir})'"
echo "Current content:"
ls -lha "${outdir}"


source init_static_params.sh

for db in $(list_dbs.py | grep "${db_regex}"); do
    echo "Dump database '${db}'."
    if [ "${dry_run}" == false ]; then
        mongodump ${SSL_OPTS} ${AUTH_OPTS} --verbose --gzip --db "${db}" --out "${outdir}"
    fi
done
