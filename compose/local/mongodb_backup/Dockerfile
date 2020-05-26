FROM mongod-on-smb

RUN mkdir -p /data/backup

# apt installs tzdata, will drop into interactive time zone configuratin without this env var
ENV DEBIAN_FRONTEND=noninteractive
RUN    apt-get update \
    && apt-get --yes install --no-install-recommends python3 python3-pip \
    && pip3 --no-cache-dir install pymongo==3.10.1 \
    && apt-get purge -y --auto-remove python3-pip \
    && rm -rf /var/lib/apt/lists/*

# NOTE: curl and gpg are obsolete now

COPY list_dbs.py /usr/local/bin/list_dbs.py
RUN chmod 700 /usr/local/bin/list_dbs.py

COPY full_dump.py /usr/local/bin/full_dump.sh
RUN chmod 700 /usr/local/bin/full_dump.sh

COPY full_restore.py /usr/local/bin/full_restore.sh
RUN chmod 700 /usr/local/bin/full_restore.sh

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 700 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/tini", "--", "docker-entrypoint.sh"]

CMD ["list_dbs.py"]