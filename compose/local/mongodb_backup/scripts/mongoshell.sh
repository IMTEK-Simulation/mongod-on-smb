#!/bin/bash
# connect from within container composition with mongodb-backup credentials
mongo --tls --tlsCAFile /run/secrets/rootCA.pem --tlsCertificateKeyFile \
        /run/secrets/mongodb_backup/tls_key_cert.pem --host mongodb --sslAllowInvalidHostnames
