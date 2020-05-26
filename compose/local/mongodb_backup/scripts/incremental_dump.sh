#!/bin/bash
# https://tech.willhaben.at/mongodb-incremental-backups-dff4c8f54d58
# https://dba.stackexchange.com/questions/107987/mongodb-incremental-backups
# https://gist.github.com/taxilian/3d74f381954ca883d64f86e43786bb09
# incremental dump of all databases matching a certain regular expression
outdir="/data/backup/DB_OPLOG_DUMP"

usage() {
  echo -n "

Usage: $(basename "$0") [OPTIONS]

  Incremental backup of oplog to '--outdir OUTDIR'
  (default: '${outdir}') using 'mongodump'.

Options:

  -h, --help
  -o, --outdir      Output directory.
"
}

args=$(getopt -n "$0" -l "help,dry-run,outdir:" -o "hno:" -- "$@")
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$args"

while true; do
  case "$1" in
    -h | --help ) usage ; exit 0 ;;
    -o | --outdir ) outdir="$2"; shift ; shift;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

source init_static_params.sh

mkdir -p -v "${outdir}"
log $LOG_MESSAGE_INFO "[INFO] output directory: '$(readlink -f ${outdir})'"
log $LOG_MESSAGE_INFO "[INFO] current content:"
ls -lha "${outdir}"

log $LOG_MESSAGE_INFO "[INFO] starting incremental backup of oplog"

LAST_OPLOG_DUMP=$(ls -t ${outdir}/*.bson.gz  2> /dev/null | head -1)

if [ "$LAST_OPLOG_DUMP" != "" ]; then
   log $LOG_MESSAGE_DEBUG "[DEBUG] last incremental oplog backup is $LAST_OPLOG_DUMP"
   set -o xtrace
   LAST_OPLOG_ENTRY=$(zcat ${LAST_OPLOG_DUMP} | bsondump | grep ts | tail -1)
   set +o xtrace
   if [ "$LAST_OPLOG_ENTRY" == "" ]; then
      log $LOG_MESSAGE_ERROR "[ERROR] evaluating last backed-up oplog entry with bsondump failed"
      exit 1
   else
      TIMESTAMP_LAST_OPLOG_ENTRY=$(echo $LAST_OPLOG_ENTRY | jq '.ts[].t')
      INC_NUMBER_LAST_OPLOG_ENTRY=$(echo $LAST_OPLOG_ENTRY | jq '.ts[].i')
      START_TIMESTAMP="{\"\$timestamp\":{\"t\":${TIMESTAMP_LAST_OPLOG_ENTRY},\"i\":${INC_NUMBER_LAST_OPLOG_ENTRY}}}"
      log $LOG_MESSAGE_DEBUG "[DEBUG] dumping everything newer than $START_TIMESTAMP"
   fi
   log $LOG_MESSAGE_DEBUG "[DEBUG] last backed-up oplog entry: $LAST_OPLOG_ENTRY"
else
   log $LOG_MESSAGE_WARN "[WARN] no backed-up oplog available. creating initial backup"
   TIMESTAMP_LAST_OPLOG_ENTRY=0000000000
   INC_NUMBER_LAST_OPLOG_ENTRY=0
fi

OPLOG_OUTFILE="${outdir}/${TIMESTAMP_LAST_OPLOG_ENTRY}_${INC_NUMBER_LAST_OPLOG_ENTRY}_oplog.bson.gz"

if [ "$LAST_OPLOG_ENTRY" != "" ]; then
   OPLOG_QUERY="{ \"ts\" : { \"\$gt\" : $START_TIMESTAMP } }"
   set -o xtrace
   mongodump ${SSL_OPTS} ${AUTH_OPTS} --verbose --collection oplog.rs --query "${OPLOG_QUERY}" --db local -o - | gzip -9 > $OPLOG_OUTFILE
   set +o xtrace
   RET_CODE=$?
else
   set -o xtrace
   mongodump ${SSL_OPTS} ${AUTH_OPTS} --verbose --collection oplog.rs --db local -o - | gzip -9 > $OPLOG_OUTFILE
   set +o xtrace
   RET_CODE=$?
fi

if [ $RET_CODE -gt 0 ]; then
   log $LOG_MESSAGE_ERROR "[ERROR] incremental backup of oplog with mongodump failed with return code $RET_CODE"
fi

FILESIZE=$(stat --printf="%s" ${OPLOG_OUTFILE})

# Note that I found many times when I had a failure I still had a 20 byte file;
# I figured anything smaller than 50 bytes isn't big enough to matter regardless
if [ $FILESIZE -lt 50 ]; then
   log $LOG_MESSAGE_WARN "[WARN] no documents have been dumped with incremental backup (no changes in mongodb since last backup?). Deleting ${OPLOG_OUTFILE}"
   rm -f ${OPLOG_OUTFILE}
else
   log $LOG_MESSAGE_INFO "[INFO] finished incremental backup of oplog to ${OPLOG_OUTFILE}"
fi