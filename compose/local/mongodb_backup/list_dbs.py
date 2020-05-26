#!/usr/bin/env python3
host = 'mongodb'
port = 27017
ssl_ca_cert='/run/secrets/rootCA.pem'
ssl_certfile='/run/secrets/mongodb_backup/tls_cert.pem'
ssl_keyfile='/run/secrets/tls_key.pem'

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
    ssl_keyfile=ssl_keyfile)

dbs = client.list_database_names()
for db in dbs:
    print(db)

client.close()
