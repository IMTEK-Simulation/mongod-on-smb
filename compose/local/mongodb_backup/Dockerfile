FROM mongod-on-smb

RUN mkdir -p /data/backup

# apt installs tzdata, will drop into interactive time zone configuratin without this env var
ENV DEBIAN_FRONTEND=noninteractive
RUN    apt-get update \
    && apt-get --yes install --no-install-recommends python3-pymongo \
    && rm -rf /var/lib/apt/lists/*

# NOTE: curl and gpg are obsolete now

COPY list_dbs.py /usr/local/bin/list_dbs.py
RUN chmod 700 /usr/local/bin/list_dbs.py

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 700 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/tini", "--", "docker-entrypoint.sh"]

CMD ["list_dbs.py"]