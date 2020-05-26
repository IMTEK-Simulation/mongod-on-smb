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

COPY scripts/* /usr/local/bin/
RUN chmod 700 /usr/local/bin/*

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 700 /usr/local/bin/docker-entrypoint.sh

COPY init_rs.js /init_rs.js

ENTRYPOINT ["/tini", "--", "docker-entrypoint.sh"]

CMD ["list_dbs.py"]