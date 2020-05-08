# FROM continuumio/miniconda3
FROM mongo:latest

# ENV PYTHONUNBUFFERED 1

RUN apt-get --yes update && apt-get --yes install cifs-utils

COPY etc/fstab /etc/fstab
COPY etc/smbcredentials /etc/smbcredentials
COPY docker-entrypoint.sh /usr/local/bin

RUN mkdir /mnt/db
RUN chmod 600 /etc/smbcredentials
RUN chmod 700 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
