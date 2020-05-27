# mongodb-backup

Copyright 2020, IMTEK Simulation, University of Freiburg

Author: Johannes Hoermann, johannes.hoermann@imtek.uni-freiburg.de

## Introduction

Does not run any `mongod` instance, but provides backup and administration utilities.

## TODO

* Run full and incremental backups as cronjobs.

## Configuration

Expects a backup volume provided at `/data/backup`. Per default, 
backups are stored within three subdirectories on this volume,

* `DB_OPLOG_DUMP` for (automized) incremental oplog backups.
* `DB_FULL_DUMP` for (automized) full backups.
* `DB_FILTERED_DUMP` for (manual) selective backups.

Expects following secrest

* `/run/secrets/rootCA.pem`
* `/run/secrets/mongodb_backup/tls_cert.pem`
* `/run/secrets/mongodb_backup/tls_key.pem`
* `/run/secrets/mongodb/username`
* `/run/secrets/mongodb/password` 

to be provided within the container at runtime.

## Content

* `list_dbs.py` lists all databases within `mongod`.
* `init_rs.sh` initializes a replica set by applaying `init_rs.js` if not done previously. This is required for ...
* `incremental_backup.sh` to create incremental oplog backups. 
* `full_backup.sh` dumps everything under `mongod`.
* `filtered_backup.sh` dumps databases whose name match a regular expression.
* `incremental_restore.sh` (untested) replays incremental oplog backups created by `incremental_backup.sh`, but requires ...
* `full_restore.sh` (untested) to have restored the latest full backup by `full_dump.sh` beforehand.
* `filtered_restore.sh` restoresdatabases matching a specific regular expression from a (partial or full) backup.

# References

* https://dba.stackexchange.com/questions/107987/mongodb-incremental-backups
* https://tech.willhaben.at/mongodb-incremental-backups-dff4c8f54d58
* https://gist.github.com/taxilian/3d74f381954ca883d64f86e43786bb09

all accessed on 2020/05/26