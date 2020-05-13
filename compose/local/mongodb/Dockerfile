FROM mongo:latest
RUN apt-get --yes update && apt-get --yes install cifs-utils && rm -rf /var/lib/apt/lists/*
COPY docker-entrypoint-initdb.d/mount-smb.sh /docker-entrypoint-initdb.d/mount-smb.sh
COPY etc/fstab /etc/fstab