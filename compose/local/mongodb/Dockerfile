# 
# modified upstream Dockerfile https://raw.githubusercontent.com/docker-library/mongo/master/4.2/Dockerfile
# upstream license:  Apache License 2.0, https://github.com/docker-library/mongo/blob/master/LICENSE
#
FROM ubuntu:bionic

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
# RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        jq \
        numactl \
    ; \
    if ! command -v ps > /dev/null; then \
        apt-get install -y --no-install-recommends procps; \
    fi; \
    rm -rf /var/lib/apt/lists/*

# grab "js-yaml" for parsing mongod's YAML config files (https://github.com/nodeca/js-yaml/releases)
ENV JSYAML_VERSION 3.13.1

RUN set -ex; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        wget \
    ; \
    if ! command -v gpg > /dev/null; then \
        apt-get install -y --no-install-recommends gnupg dirmngr; \
        savedAptMark="$savedAptMark gnupg dirmngr"; \
    elif gpg --version | grep -q '^gpg (GnuPG) 1\.'; then \
# "This package provides support for HKPS keyservers." (GnuPG 1.x only)
        apt-get install -y --no-install-recommends gnupg-curl; \
    fi; \
    rm -rf /var/lib/apt/lists/*; \
    \
    wget -O /js-yaml.js "https://github.com/nodeca/js-yaml/raw/${JSYAML_VERSION}/dist/js-yaml.js"; \
# TODO some sort of download verification here
    \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark > /dev/null; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

RUN mkdir /docker-entrypoint-initdb.d

ENV GPG_KEYS E162F504A20CDF15827F718D4B7C549A058F8B6B
RUN set -ex; \
    export GNUPGHOME="$(mktemp -d)"; \
    for key in $GPG_KEYS; do \
        gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    done; \
    gpg --batch --export $GPG_KEYS > /etc/apt/trusted.gpg.d/mongodb.gpg; \
    command -v gpgconf && gpgconf --kill all || :; \
    rm -r "$GNUPGHOME"; \
    apt-key list

# Allow build-time overrides (eg. to build image with MongoDB Enterprise version)
# Options for MONGO_PACKAGE: mongodb-org OR mongodb-enterprise
# Options for MONGO_REPO: repo.mongodb.org OR repo.mongodb.com
# Example: docker build --build-arg MONGO_PACKAGE=mongodb-enterprise --build-arg MONGO_REPO=repo.mongodb.com .
ARG MONGO_PACKAGE=mongodb-org
ARG MONGO_REPO=repo.mongodb.org
ENV MONGO_PACKAGE=${MONGO_PACKAGE} MONGO_REPO=${MONGO_REPO}

ENV MONGO_MAJOR 4.2
ENV MONGO_VERSION 4.2.7
# bashbrew-architectures:amd64 arm64v8 s390x
RUN echo "deb http://$MONGO_REPO/apt/ubuntu bionic/${MONGO_PACKAGE%-unstable}/$MONGO_MAJOR multiverse" | tee "/etc/apt/sources.list.d/${MONGO_PACKAGE%-unstable}.list"

RUN set -x \
# installing "mongodb-enterprise" pulls in "tzdata" which prompts for input
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y \
        ${MONGO_PACKAGE}=$MONGO_VERSION \
        ${MONGO_PACKAGE}-server=$MONGO_VERSION \
        ${MONGO_PACKAGE}-shell=$MONGO_VERSION \
        ${MONGO_PACKAGE}-mongos=$MONGO_VERSION \
        ${MONGO_PACKAGE}-tools=$MONGO_VERSION \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mongodb \
    && mv /etc/mongod.conf /etc/mongod.conf.orig

RUN mkdir -p /data/db /data/configdb
#
# end of modified upstream Dockerfile
#

# apt installs tzdata, will drop into interactive time zone configuratin without this env var
ENV TINI_VERSION=v0.19.0
ENV DEBIAN_FRONTEND=noninteractive
RUN    apt-get update \
    && apt-get --yes install --no-install-recommends curl gpg \
    && curl -L -o /tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini \
    && curl -L -o /tini.asc https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc \
    && gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
    && gpg --batch --verify /tini.asc /tini \
    && apt-get purge --yes curl gpg \
    && apt-get purge --yes --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm /tini.asc \
    && rm -rf /var/lib/apt/lists/* \
    && chmod +x /tini

# NOTE: curl and gpg are obsolete now

COPY etc/mongod.conf /etc/mongod.conf

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 700 /usr/local/bin/docker-entrypoint.sh

COPY docker-entrypoint-upstream.sh /usr/local/bin/docker-entrypoint-upstream.sh
RUN chmod 700 /usr/local/bin/docker-entrypoint-upstream.sh

# set timezone
ENV TZ=Europe/Berlin
RUN echo $TZ > /etc/timezone && \
    apt-get update && apt-get install -y tzdata && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/tini", "--", "docker-entrypoint.sh"]

EXPOSE 27017
CMD ["mongod"]