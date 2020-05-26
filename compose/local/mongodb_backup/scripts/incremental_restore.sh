#!/bin/bash
# https://tech.willhaben.at/mongodb-incremental-backups-dff4c8f54d58
# https://dba.stackexchange.com/questions/107987/mongodb-incremental-backups
# https://gist.github.com/taxilian/3d74f381954ca883d64f86e43786bb09
# incremental dump of all databases matching a certain regular expression

oplog_indir="/data/backup/DB_OPLOG_DUMP"
full_dump_indir="/data/backup/DB_FULL_DUMP"
oplog_limit=$(date +%s)

usage() {
  echo -n "

Usage: $(basename "$0") [OPTIONS]

  Restauration from incremental oplog backups within
  '--indir OUTDIR' (default: '${indir}') using 'mongorestore'.

Options:

  -h, --help
  --oplog-limit       Timestamp up unto which to apply backups
                      The timestamp is a unix timestamp.
                      If your desaster happened for example on
                      2017-18-10 12:20 and you want to restore until 12:19
                      your timestamp is 'date -d \"2017-10-18 12:19:00\" +%s'
  --oplog-indir       Location of incremental oplog backups.
  --full-dump-indir   Location of full backups.
"
}

args=$(getopt -n "$0" -l "help,dry-run,oplog-indir:,oplog-limit:,full-dump-indir" -o "hn" -- "$@")
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$args"

while true; do
  case "$1" in
    -h | --help ) usage ; exit 0 ;;
    --oplog-limit ) oplog_limit="$2"; shift ; shift;;
    --oplog-indir ) oplog_indir="$2"; shift ; shift;;
    --full-dump-indir ) full_dump_indir="$2"; shift ; shift;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

source init_static_params.sh

FULL_DUMP_TIMESTAMP=$(echo ${full_dump_indir} | cut -d "_" -f 2 | cut -d "/" -f 1)
LAST_OPLOG=""
ALREADY_APPLIED_OPLOG=0

mkdir -p /tmp/emptyDirForOpRestore
for OPLOG in $(ls ${oplog_indir}/*.bson.gz); do
   OPLOG_TIMESTAMP=$(echo $OPLOG | rev | cut -d "/" -f 1 | rev | cut -d "_" -f 1)
   if [ $OPLOG_TIMESTAMP -gt $FULL_DUMP_TIMESTAMP ]; then
      if [ $ALREADY_APPLIED_OPLOG -eq 0 ]; then
         ALREADY_APPLIED_OPLOG=1
         echo "applying oplog $LAST_OPLOG"
         mongorestore ${SSL_OPTS} ${AUTH_OPTS} --verbose --gzip --oplogFile $LAST_OPLOG --oplogReplay --dir /tmp/emptyDirForOpRestore --oplogLimit=${oplog_limit}
         echo "applying oplog $OPLOG"
         mongorestore ${SSL_OPTS} ${AUTH_OPTS} --verbose --gzip --oplogFile $OPLOG --oplogReplay --dir /tmp/emptyDirForOpRestore --oplogLimit=${oplog_limit}
      else
         echo "applying oplog $OPLOG"
         mongorestore ${SSL_OPTS} ${AUTH_OPTS} --verbose --gzip --oplogFile $OPLOG --oplogReplay --dir /tmp/emptyDirForOpRestore --oplogLimit=${oplog_limit}
      fi
   else
      LAST_OPLOG=$OPLOG
   fi
done
rmdir /tmp/emptyDirForOpRestore

if [ $ALREADY_APPLIED_OPLOG -eq 0 ]; then
   if [ "$LAST_OPLOG" != "" ]; then
         echo "applying oplog $LAST_OPLOG"
     mongorestore ${SSL_OPTS} ${AUTH_OPTS} --verbose --oplogFile $LAST_OPLOG --oplogReplay --dir ${oplog_indir} --oplogLimit=${oplog_limit}
   fi
fi
