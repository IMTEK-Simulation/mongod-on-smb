Mount an smb share holding raw db within mongo conatiner.

Repository does not include sensitive data. Before building,
create subfolder `secrets` if not present, place files

    mongo_root_password
    mongo_root_username
    smbcredentials

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

Look at the database at `http://localhost:8081`.

References:

    Mounting samba share in docker container:
        https://github.com/moby/moby/issues/22197
        https://stackoverflow.com/questions/27989751/mount-smb-cifs-share-within-a-docker-container
    MongoDB & docker:
        https://hub.docker.com/_/mongo
        https://hub.docker.com/_/mongo-express
        https://github.com/mongo-express/mongo-express
        https://github.com/mongo-express/mongo-express/blob/e4777b6f8bce62d204e9c4204801e2cb7a7b8898/config.default.js#L41
        https://github.com/mongo-express/mongo-express-docker

    Sensitive data:
        https://docs.docker.com/compose/compose-file/#secrets
        https://docs.docker.com/compose/compose-file/#secrets-configuration-reference

    Related configurations:
        https://github.com/pastewka/dtool_lookup_docker