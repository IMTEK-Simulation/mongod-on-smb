# IMTEK Simulation MongoDB

2020/05, Johannes Hoermann, johannes.hoermann@imtek.uni-freiburg.de

## Summary

Mount an smb share holding raw db within mongo conatiner and publish
standard port 27017 via TLS/SSL encryption globally.

Additionaly provide mongo-express web interface locally.

mongo-express service with TLS/SSL encryption service requires a slightly 
modified Docker image suggested at

* https://github.com/mongo-express/mongo-express/pull/574
* https://github.com/mongo-express/mongo-express/pull/575

Tested with mongo 4.2.6 and modified mongo-express 0.54.0.

## Setup with Docker

### Contents

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

### Processes

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

### Debugging

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

## Setup with Podman

Podman runs with user privileges. The `cifs` driver for smb shares requires
elevated privileges for mount operations. Thus, it must be replaced
by a pure userland approach. The described setup bases on the FUSE
drivers `smbnetfs` and `bindfs`.

### Capabilities

Granted capabilities are prefixed by `CAP_`, i.e.

    cap_add:
      - CAP_SYS_ADMIN

for Podman compared to

    cap_add:
      - SYS_ADMIN

for Docker within the `compose.yml` file. This capability in connection with

    devices:
      - /dev/fuse

is necessary for enabling the use of FUSE file system drivers within the unprivileged
container.

### Secrets

podman does not handle `secrets` the way docker does. Similar behavior can be achieved with
a per-user configuration file `$HOME/.config/containers/mounts.conf` on the host containing, 
for example, a line

    /home/user/containers/secrets:/run/secrets

that will make the content of `/home/user/containers/secrets` on the host available under
`/run/secrets` within *all containers* of the evoking user. The owner and group within 
the container will be `root:root` and file permissions will correspond to permissions 
on the host file system. Thus, an entrypoint script might have to adapt permissions.

For this composition, the following secrets must be available:

- smb share credentials
  - `/run/secrets/smbnetfs-smbshare-mountpoint`, mongo-on-smb,
  - `/run/secrets/smbnetfs.auth`, mongo-on-smb, 
- mongod credentials & certificates
  - `/run/secrets/mongodb/username`, mongo-on-smb, mongo-express
  - `/run/secrets/mongodb/password`, mongo-on-smb, mongo-express
  - `/run/secrets/tls_CA.pem`, mongo-on-smb
  - `/run/secrets/mongodb/tls_key_and_cert.pem`, mongo-on-smb
  - `/run/secrets/mongodb/tls_cert.pem`, mongo-express
  - `/run/secrets/mongodb/tls_key.pem`, mongo-express
- mongo-express web gui credentials & certificates
  - `/run/secrets/mongo_express/username`
  - `/run/secrets/mongo_express/password`
  - `/run/secrets/mongo_express/tls_key.pem`
  - `/run/secrets/mongo_express/tls_cert.pem`

### podman-compose

As of 2020/05/20, `podman-compose` v 0.1.5 published on PyPi does not support the `devices`
option. The current development version of `podman-compose` implements it, but is broken at
https://github.com/containers/podman-compose/blob/64ed5545437c1348b65b5f9a4298c2212d3d6419/podman_compose.py#L1079

Simple fix  https://github.com/jotelha/podman-compose/tree/20200520_no_args_build_arg 
provides working podman-compose for our setup.

## References

- Certificates:
  - https://medium.com/@rajanmaharjan/secure-your-mongodb-connections-ssl-tls-92e2addb3c89
- Docker setup
  - Mounting samba share in docker container:
    - https://github.com/moby/moby/issues/22197
    - https://stackoverflow.com/questions/27989751/mount-smb-cifs-share-within-a-docker-container
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
- Podman setup
  - Sensitive data
    - https://www.projectatomic.io/blog/2018/06/sneak-secrets-into-containers/
  - FUSE-related
    - https://bindfs.org/
    - https://bindfs.org/docs/bindfs-help.txt
    - https://rhodesmill.org/brandon/2010/mounting-windows-shares-in-linux-userspace/
- Related configurations:
  - https://github.com/pastewka/dtool_lookup_docker

## Issues

### MongoDB warnings

mongod warns about

```
** WARNING: /sys/kernel/mm/transparent_hugepage/enabled is 'always'.
**        We suggest setting it to 'never'
```

at startup, see https://docs.mongodb.com/manual/tutorial/transparent-huge-pages/.
THP (Transparent HugePages) would have to be disabled at host boot. 

### Unprivileged GVFS
Using `gvfs` and `bindfs` to provide the database, WiredTiger fails:

```
root@5071f576509d:/# cat /data/db/docker-initdb.log
2020-05-21T10:11:01.770+0000 I  CONTROL  [main] Automatically disabling TLS 1.0, to force-enable TLS 1.0 specify --sslDisabledProtocols 'none'
2020-05-21T10:11:01.776+0000 W  ASIO     [main] No TransportLayer configured during NetworkInterface startup
2020-05-21T10:11:01.779+0000 I  CONTROL  [initandlisten] MongoDB starting : pid=139 port=27017 dbpath=/data/db 64-bit host=5071f576509d
2020-05-21T10:11:01.780+0000 I  CONTROL  [initandlisten] db version v4.2.6
2020-05-21T10:11:01.782+0000 I  CONTROL  [initandlisten] git version: 20364840b8f1af16917e4c23c1b5f5efd8b352f8
2020-05-21T10:11:01.783+0000 I  CONTROL  [initandlisten] OpenSSL version: OpenSSL 1.1.1  11 Sep 2018
2020-05-21T10:11:01.785+0000 I  CONTROL  [initandlisten] allocator: tcmalloc
2020-05-21T10:11:01.785+0000 I  CONTROL  [initandlisten] modules: none
2020-05-21T10:11:01.786+0000 I  CONTROL  [initandlisten] build environment:
2020-05-21T10:11:01.787+0000 I  CONTROL  [initandlisten]     distmod: ubuntu1804
2020-05-21T10:11:01.788+0000 I  CONTROL  [initandlisten]     distarch: x86_64
2020-05-21T10:11:01.789+0000 I  CONTROL  [initandlisten]     target_arch: x86_64
2020-05-21T10:11:01.790+0000 I  CONTROL  [initandlisten] options: { config: "/tmp/docker-entrypoint-temp-config.json", net: { bindIp: "127.0.0.1", port: 27017, tls: { mode: "disabled" } }, processManagement: { fork: true, pidFilePath: "/tmp/docker-entrypoint-temp-mongod.pid" }, systemLog: { destination: "file", logAppend: true, path: "/data/db/docker-initdb.log" } }
2020-05-21T10:11:01.849+0000 I  STORAGE  [initandlisten] wiredtiger_open config: create,cache_size=3394M,cache_overflow=(file_max=0M),session_max=33000,eviction=(threads_min=4,threads_max=4),config_base=false,statistics=(fast),log=(enabled=true,archive=true,path=journal,compressor=snappy),file_manager=(close_idle_time=100000,close_scan_interval=10,close_handle_minimum=250),statistics_log=(wait=0),verbose=[recovery_progress,checkpoint_progress],
2020-05-21T10:11:02.611+0000 E  STORAGE  [initandlisten] WiredTiger error (95) [1590055862:611142][139:0x7fe5fe559b00], file:WiredTiger.wt, connection: __posix_open_file, 667: /data/db/WiredTiger.wt: handle-open: open: Operation not supported Raw: [1590055862:611142][139:0x7fe5fe559b00], file:WiredTiger.wt, connection: __posix_open_file, 667: /data/db/WiredTiger.wt: handle-open: open: Operation not supported
2020-05-21T10:11:02.625+0000 E  STORAGE  [initandlisten] WiredTiger error (95) [1590055862:625022][139:0x7fe5fe559b00], wiredtiger_open: __posix_open_file, 667: /data/db/WiredTiger.lock: handle-open: open: Operation not supported Raw: [1590055862:625022][139:0x7fe5fe559b00], wiredtiger_open: __posix_open_file, 667: /data/db/WiredTiger.lock: handle-open: open: Operation not supported
2020-05-21T10:11:02.628+0000 E  STORAGE  [initandlisten] WiredTiger error (95) [1590055862:628694][139:0x7fe5fe559b00], wiredtiger_open: __posix_open_file, 667: /data/db/WiredTiger.lock: handle-open: open: Operation not supported Raw: [1590055862:628694][139:0x7fe5fe559b00], wiredtiger_open: __posix_open_file, 667: /data/db/WiredTiger.lock: handle-open: open: Operation not supported
2020-05-21T10:11:02.632+0000 E  STORAGE  [initandlisten] WiredTiger error (95) [1590055862:632835][139:0x7fe5fe559b00], wiredtiger_open: __posix_open_file, 667: /data/db/WiredTiger.lock: handle-open: open: Operation not supported Raw: [1590055862:632835][139:0x7fe5fe559b00], wiredtiger_open: __posix_open_file, 667: /data/db/WiredTiger.lock: handle-open: open: Operation not supported
2020-05-21T10:11:02.636+0000 E  STORAGE  [initandlisten] WiredTiger error (95) [1590055862:636325][139:0x7fe5fe559b00], wiredtiger_open: __posix_open_file, 667: /data/db/WiredTiger.lock: handle-open: open: Operation not supported Raw: [1590055862:636325][139:0x7fe5fe559b00], wiredtiger_open: __posix_open_file, 667: /data/db/WiredTiger.lock: handle-open: open: Operation not supported
2020-05-21T10:11:02.637+0000 W  STORAGE  [initandlisten] Failed to start up WiredTiger under any compatibility version.
2020-05-21T10:11:02.638+0000 F  STORAGE  [initandlisten] Reason: 95: Operation not supported
2020-05-21T10:11:02.639+0000 F  -        [initandlisten] Fatal Assertion 28595 at src/mongo/db/storage/wiredtiger/wiredtiger_kv_engine.cpp 915
2020-05-21T10:11:02.639+0000 F  -        [initandlisten] 

***aborting after fassert() failure
```

The `__posix_open_file` operation fails at https://github.com/wiredtiger/wiredtiger/blob/8de74488f2bb2b5cba0404c345f568a2f72478d3/src/os_posix/os_fs.c#L661-L667

```C
    WT_SYSCALL_RETRY(((pfh->fd = open(name, f, mode)) == -1 ? -1 : 0), ret);
    if (ret != 0)
        WT_ERR_MSG(session, ret,
          pfh->direct_io ? "%s: handle-open: open: failed with direct I/O configured, "
                           "some filesystem types do not support direct I/O" :
                           "%s: handle-open: open",
          name);
```

Likely, gvfs does not support `direct_io`.

