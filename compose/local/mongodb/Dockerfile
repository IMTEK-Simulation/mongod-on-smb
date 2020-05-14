FROM mongo:latest
RUN apt-get --yes update && apt-get --yes install cifs-utils && rm -rf /var/lib/apt/lists/*

COPY etc/mongod.conf /etc/mongod.conf
COPY etc/fstab /etc/fstab

COPY docker-entrypoint.sh /usr/local/bin/downstream-docker-entrypoint.sh
RUN chmod 700 /usr/local/bin/downstream-docker-entrypoint.sh

ENTRYPOINT ["downstream-docker-entrypoint.sh"]
CMD ["mongod"]