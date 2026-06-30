ARG DOCKER_REGISTRY=registry-1.docker.io
FROM ${DOCKER_REGISTRY}/library/postgres:16.13-alpine3.23@sha256:4e6e670bb069649261c9c18031f0aded7bb249a5b6664ddec29c013a89310d50

ARG PGAUDIT_VERSION=16.1
ARG PGAUDIT_SHA256_HASH=01343a72d7eff31e40c8e646dd17f236dc07389205f57ab13000298f38f0a9fd

RUN apk add --no-cache --virtual .build-deps \
  curl \
  unzip \
  make \
  gcc \
  musl-dev \
  postgresql-dev \
  krb5-dev \
  libc-dev \
  llvm19 \
  clang19

WORKDIR /pgaudit
RUN curl -fL -O https://github.com/pgaudit/pgaudit/archive/refs/tags/${PGAUDIT_VERSION}.zip \
  && echo "${PGAUDIT_SHA256_HASH}  ${PGAUDIT_VERSION}.zip" | sha256sum -c - \
  && unzip ${PGAUDIT_VERSION}.zip \
  && make -C ./pgaudit-${PGAUDIT_VERSION} install USE_PGXS=1 PG_CONFIG=/usr/local/bin/pg_config \
  && apk del .build-deps \
  && rm -rf /pgaudit
