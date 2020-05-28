#!/usr/bin/env python3
host = 'mongodb'
port = 27017
ssl_ca_cert='/run/secrets/rootCA.pem'
ssl_certfile='/run/secrets/mongodb_backup/tls_cert.pem'
ssl_keyfile='/run/secrets/mongodb_backup/tls_key.pem'

# don't turn these signal into exceptions, just die.
# necessary for integrating into bash script pipelines seamlessly.
import signal
signal.signal(signal.SIGINT, signal.SIG_DFL)
signal.signal(signal.SIGPIPE, signal.SIG_DFL)

# get administrator credentials
with open('/run/secrets/mongodb/username','r') as f:
    username = f.read()

with open('/run/secrets/mongodb/password','r') as f:
    password = f.read()

from pymongo import MongoClient

client = MongoClient(host, port,
    ssl=True,
    username=username,
    password=password,
    authSource=username, # assume admin database and admin user share name
    ssl_ca_certs=ssl_ca_cert,
    ssl_certfile=ssl_certfile,
    ssl_keyfile=ssl_keyfile,
    tlsAllowInvalidHostnames=True)
# Within the container environment, mongod runs on host 'mongodb'.
# That hostname, however, is not mentioned within the host certificate.

dbs = client.list_database_names()
for db in dbs:
    print(db)

client.close()
