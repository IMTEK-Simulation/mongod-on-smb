FROM mongod-on-smb

RUN mkdir -p /data/backup

# apt might install tzdata, will drop into interactive time zone configuratin without this env var
ENV DEBIAN_FRONTEND=noninteractive
RUN    apt-get update \
    && apt-get --yes install --no-install-recommends python3 python3-pip \
    && pip3 --no-cache-dir install pymongo==3.10.1 \
    && apt-get purge -y --auto-remove python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install cronn scheduler
RUN    apt-get update \
    && apt-get --yes install --no-install-recommends cron \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# place scripts on path
COPY scripts/* /usr/local/bin/
RUN chmod 700 /usr/local/bin/*

# configure regular backup tasks
RUN ln -s /usr/local/bin/full_dump.sh /etc/cron.monthly/full_dump
RUN ln -s /usr/local/bin/incremental_dump.sh /etc/cron.daily/incremental_dump

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 700 /usr/local/bin/docker-entrypoint.sh

COPY init_rs.js /init_rs.js

ENTRYPOINT ["/tini", "--", "docker-entrypoint.sh"]

CMD ["cron", "-f"]