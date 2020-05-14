# IMTEK Simulation MongoDB

2020/05/14, Johannes Hörmann, johannes.hoermann@imtek.uni-freiburg.de

## Summary

Mount an smb share holding raw db within mongo conatiner and publish
standard port 27017 via TLS/SSL encryption globally.

Additionaly provide mongo-express web interface locally.

mongo-express service with TLS/SSL encryption service requires a slightly 
modified Docker image suggested at

* https://github.com/mongo-express/mongo-express/pull/574
* https://github.com/mongo-express/mongo-express/pull/575

Tested with mongo 4.2.6 and modified mongo-express 0.54.0.

## Contents

Repository must not include sensitive data. Replace all dummy keys and
passwords before deplying. Generate self-signed testing certificates below
subfolder `keys` with

```bash
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem
openssl genrsa -out mongodb.key 2048
openssl req -new -key mongodb.key -out mongodb.csr
openssl x509 -req -in mongodb.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out mongodb.crt -days 500 -sha256
cat mongodb.key mongodb.crt > mongodb.pem 
```

Create subfolder `secrets` if not present, place files

    smbcredentials
    mongo_root_password
    mongo_root_username
    mongo_express_password
    mongo_express_username

within `./secrets` and fill with according values. `smbcredentials`
must have structure 

    username=USER
    password=PASS
    domain=DOMAIN

where `DOMAIN` is oftentimes `WORKGROUP` or `PUBLIC` and adapt
content of `./etc/fstab` to point to desired samba share.

The raw database must reside directly within the share or share's
subfolder specified within `./etc/fstab`. If directory is empty,
then db will be created with default administrator name and password
as in the docker secrets above. Finally, build and run with

    docker-compose up

Note: Bringing up the db on an smb share might take time. The
`mongo-express` service will fail several times before succeeding to
connect to the `mongod`service.

Look at the database at `https://localhost:8081` or try to connect to the database
from within the mongo container with

    mongo --tls --tlsCAFile /run/secrets/tls_CA.pem --tlsCertificateKeyFile \
        /run/secrets/tls_key_and_cert.pem --host mongodb

or from the host system

     mongo --tls --tlsCAFile keys/rootCA.pem \
        --tlsCertificateKeyFile keys/mongodb.pem --sslAllowInvalidHostnames

if the FQDN in the server's certificate has been set to the service's name 
'mongodb'.

## Processes

Process tree of mongodb service:

```console
$ pstree -alt
root@25105db69b6c:/# pstree -alt  
docker-init -- downstream-docker-entrypoint.sh --config /etc/mongod.conf
  `-bash /usr/local/bin/downstream-docker-entrypoint.sh --config /etc/mongod.conf
      |-mongod --config /etc/mongod.conf --auth --bind_ip_all
      |   |-{Backgro.kSource}
      |   |-{Collect.xecutor}
      |   |-{DeadlineMonitor}
      |   |-{FlowCon.fresher}
      |   |-{FreeMon.ocessor}
      |   |-{FreeMonHTTP-0}
      |   |-{FreeMonNet}
      |   |-{Logical.Refresh}
      |   |-{Logical.cheReap}
      |   |-{Periodi.kRunner}
      |   |-{TTLMonitor}
      |   |-{Timesta.Monitor}
      |   |-{WTCheck.tThread}
      |   |-{WTIdleS.Sweeper}
      |   |-{WTJourn.Flusher}
      |   |-{clientcursormon}
      |   |-{conn1}
      |   |-{conn2}
      |   |-{ftdc}
      |   |-{listener}
      |   |-9*[{mongod}]
      |   |-{signalP.gThread}
      |   |-{startPe.actions}
      |   |-{startPe.ressure}
      |   `-{waitForMajority}
      `-tail -f /dev/null
```

Process tree of mongo-express:

```console
tini -- npm start
  `-npm                          
      |-sh -c cross-env NODE_ENV=production node app
      |   `-node /app/node_modules/.bin/cross-env NODE_ENV=production node app
      |       |-node app
      |       |   `-9*[{node}]
      |       `-5*[{node}]
      |-5*[{node}]
      `-4*[{npm}]
```

## Debugging

In case of connectivity issues with mongo-express, publish the port 9229 when 
launching the according container with an interactive shell, i.e. with

    docker-compose run -p 19229:9229 mongo-express bash

run

    npm install cross-env

within and evoke the application with 

    node --inspect-brk=0.0.0.0 app.js

`--inspect-brk` causes a breakpoint before execution and `=0.0.0.0` allows the
debug session to be accessed from the host. On the host, navigate to 
`chrome://inspect` within a chromium-based browser and add `localhost:19229` 
to the target discovery settings opened bia button 'configure'.
The debug session should be detected automatically.

## References

- Mounting samba share in docker container:
  - https://github.com/moby/moby/issues/22197
  - https://stackoverflow.com/questions/27989751/mount-smb-cifs-share-within-a-docker-container
- Certificates:
  - https://medium.com/@rajanmaharjan/secure-your-mongodb-connections-ssl-tls-92e2addb3c89
- Sensitive data:
  - https://docs.docker.com/compose/compose-file/#secrets
  - https://docs.docker.com/compose/compose-file/#secrets-configuration-reference
- MongoDB, mongo-express & docker:
  - https://hub.docker.com/_/mongo
  - https://docs.mongodb.com/manual/administration/security-checklist/
  - https://hub.docker.com/_/mongo-express
  - https://github.com/mongo-express/mongo-express
  - https://github.com/mongo-express/mongo-express/blob/e4777b6f8bce62d204e9c4204801e2cb7a7b8898/config.default.js#L41
  - https://github.com/mongo-express/mongo-express-docker
  - https://github.com/mongo-express/mongo-express/pull/574
- Related configurations:
  - https://github.com/pastewka/dtool_lookup_docker