FROM alpine:3.15 as builder

# ADD ADDITIONAL MODULES
FROM redislabs/redisearch:latest as redisearch
FROM redislabs/redisgraph:latest as redisgraph
FROM redislabs/redistimeseries:latest as redistimeseries
FROM redislabs/rejson:latest as rejson

MAINTAINER NIMBIT

LABEL VERSION=1.0 \
      ARCH=AMD64 \
      DESCRIPTION="A production grade performance tuned redis docker image created by Opstree Solutions and edited by nimbit"

ARG REDIS_DOWNLOAD_URL="http://download.redis.io/"

ARG REDIS_VERSION="stable"

RUN apk add --no-cache su-exec tzdata make curl build-base linux-headers bash openssl-dev

RUN curl -fL -Lo /tmp/redis-${REDIS_VERSION}.tar.gz ${REDIS_DOWNLOAD_URL}/redis-${REDIS_VERSION}.tar.gz && \
    cd /tmp && \
    tar xvzf redis-${REDIS_VERSION}.tar.gz && \
    cd redis-${REDIS_VERSION} && \
    make && \
    make install BUILD_TLS=yes

# ADD ADDITIONAL MODULES
ENV LD_LIBRARY_PATH /usr/lib/redis/modules

COPY --from=redisearch ${LD_LIBRARY_PATH}/redisearch.so ${LD_LIBRARY_PATH}/
COPY --from=redistimeseries ${LD_LIBRARY_PATH}/*.so ${LD_LIBRARY_PATH}/
COPY --from=rejson ${LD_LIBRARY_PATH}/*.so ${LD_LIBRARY_PATH}/

FROM alpine:3.15

MAINTAINER Opstree Solutions

LABEL VERSION=1.0 \
      ARCH=AMD64 \
      DESCRIPTION="A production grade performance tuned redis docker image created by Opstree Solutions"

COPY --from=builder /usr/local/bin/redis-server /usr/local/bin/redis-server
COPY --from=builder /usr/local/bin/redis-cli /usr/local/bin/redis-cli

COPY --from=builder /usr/lib/redis/modules /usr/lib/redis/modules

RUN addgroup -S -g 1000 redis && adduser -S -G redis -u 1000 redis && \
    apk add --no-cache bash

COPY redis.conf /etc/redis/redis.conf

COPY entrypoint.sh /usr/bin/entrypoint.sh

COPY setupMasterSlave.sh /usr/bin/setupMasterSlave.sh

COPY healthcheck.sh /usr/bin/healthcheck.sh

RUN chown -R redis:redis /etc/redis

VOLUME ["/data"]

WORKDIR /data

EXPOSE 6379

USER 1000

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
