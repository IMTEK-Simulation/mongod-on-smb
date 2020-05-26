#!/bin/bash
# restore all databases matching a certain regular expression...
db_regex='^fireworks-'
# ...within latest backup per default
indir=$(ls -t1d --group-directories-first /data/backup/DBDUMP/* | head -n 1)
dry_run=false

usage() {
  echo -n "

Usage: $(basename "$0") [OPTIONS]

  Restores databases with name matching '--regex REGEX' (default: '${db_regex}')
  from mongodump archives within '--indir INDIR' (default: '${indir}') using 'mongorestore'.

Options:

  -h, --help
  -n, --dry-run     Show databases in filter, but don't actually dump.
  -r, --regex       Regular expression filter on database names.
  -i, --indir      Output directory.
"
}

args=$(getopt -n "$0" -l "help,dry-run,regex:,indir:" -o "hnr:i:" -- "$@")
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$args"

while true; do
  case "$1" in
    -h | --help ) usage ; exit 0 ;;
    -n | --dry-run ) dry_run=true; shift;;
    -r | --regex ) db_regex="$2"; shift ; shift;;
    -o | --indir ) indir="$2"; shift ; shift;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

echo "Regex filter:     '${db_regex}'"
echo "Input directory: '$(readlink -f ${indir})'"
echo "Current content:"
ls -lha "${indir}"

source init_static_params.sh

for db in $(ls -1 "${indir}" | grep "${db_regex}"); do
    echo "Restore database '${db}'."
    if [ "${dry_run}" == false ]; then
        mongorestore ${SSL_OPTS} ${AUTH_OPTS} --gzip --db "${db}" "${indir}/${db}"
    fi
done
