#!/bin/bash
# connect from within container composition with mongodb-backup credentials
source init_static_params.sh
mongo ${TLS_OPTS} ${AUTH_OPTS}
