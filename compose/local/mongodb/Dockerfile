FROM mongo:latest
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /tini.asc
RUN gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
 && gpg --batch --verify /tini.asc /tini
RUN chmod +x /tini

RUN apt-get --yes update \
    && apt-get --yes install smbnetfs bindfs \
    && rm -rf /var/lib/apt/lists/*

COPY etc/fuse.conf /etc/fuse.conf
COPY etc/smbnetfs.conf /etc/smbnetfs.conf
COPY etc/mongod.conf /etc/mongod.conf

COPY docker-entrypoint.sh /usr/local/bin/downstream-docker-entrypoint.sh
RUN chmod 700 /usr/local/bin/downstream-docker-entrypoint.sh

ENTRYPOINT ["/tini", "--"]
CMD ["downstream-docker-entrypoint.sh", "mongod"]