FROM mongo:latest
RUN apt-get --yes update \
    && apt-get --yes install smbnetfs bindfs \
    && rm -rf /var/lib/apt/lists/*

COPY etc/fuse.conf /etc/fuse.conf
COPY etc/smbnetfs.conf /etc/smbnetfs.conf
COPY etc/mongod.conf /etc/mongod.conf

COPY docker-entrypoint.sh /usr/local/bin/downstream-docker-entrypoint.sh
RUN chmod 700 /usr/local/bin/downstream-docker-entrypoint.sh

ENTRYPOINT ["downstream-docker-entrypoint.sh"]
CMD ["mongod"]