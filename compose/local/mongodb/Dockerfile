# ARG VERSION=latest
# FROM ubuntu:20.04
FROM mongo:latest
# ENV PYTHONUNBUFFERED 1

RUN apt-get --yes update && apt-get --yes install cifs-utils && rm -rf /var/lib/apt/lists/*

COPY etc/fstab /etc/fstab
COPY etc/smbcredentials /etc/smbcredentials
RUN chmod 600 /etc/smbcredentials

COPY docker-entrypoint.sh /usr/local/bin/downstream-docker-entrypoint.sh
RUN chmod 700 /usr/local/bin/downstream-docker-entrypoint.sh

# RUN mkdir -p /data/db
ENTRYPOINT ["downstream-docker-entrypoint.sh"]
CMD ["mongod"]