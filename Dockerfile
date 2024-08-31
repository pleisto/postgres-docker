FROM postgres:15-alpine AS ext_build

ENV PLV8_VERSION=3.2.2
ENV PGVECTOR_VERSION=0.7.4
ENV PG_MAJOR=15

ARG BIGINT_GRACEFUL_VALUE='BIGINT_GRACEFUL=1'
ARG BIGINT_GRACEFUL
ARG BIGINT_GRACEFUL_FLAG=${BIGINT_GRACEFUL:+$BIGINT_GRACEFUL_VALUE}

RUN apk update \
  && apk add --no-cache --virtual .v8-build \
  libstdc++-dev \
  binutils \
  gcc \
  libc-dev \
  g++ \
  ca-certificates \
  curl \
  make \
  libbz2 \
  linux-headers \
  cmake \
  clang15-libs \
  clang15 \
  llvm15 \
  ncurses-libs \
  zlib-dev \
  git \
  python3

RUN mkdir -p /tmp/build \
  && curl -o /tmp/build/v$PLV8_VERSION.tar.gz -SL "https://github.com/plv8/plv8/archive/refs/tags/v${PLV8_VERSION}.tar.gz" \
  && cd /tmp/build \
  && tar -xzf /tmp/build/v$PLV8_VERSION.tar.gz -C /tmp/build/ \
  && cd /tmp/build/plv8-$PLV8_VERSION/deps \
  && git clone https://github.com/bnoordhuis/v8-cmake.git \
  && cd ./v8-cmake \
  && git checkout beb327f02f4a7e200b9ec \
  && cd /tmp/build/plv8-$PLV8_VERSION \
  && git init \
  && make ${BIGINT_GRACEFUL_FLAG} \
  && make install \
  && strip /usr/local/lib/postgresql/plv8-${PLV8_VERSION}.so

RUN cd /tmp/build \
  && git clone --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git \
  && (cd pgvector && make && make install)

RUN apk del --no-network .v8-build; \
  rm -rf /tmp/* /var/tmp/*


FROM postgres:15-alpine
ENV PLV8_VERSION=3.2.2
COPY --from=ext_build /usr/local/share/postgresql/extension/ /usr/local/share/postgresql/extension/
COPY --from=ext_build /usr/local/lib/postgresql/bitcode/ /usr/local/lib/postgresql/bitcode/
COPY --from=ext_build /usr/local/lib/postgresql/plv8-${PLV8_VERSION}.so /usr/local/lib/postgresql/plv8-${PLV8_VERSION}.so
COPY --from=ext_build /usr/local/lib/postgresql/vector.so /usr/local/lib/postgresql/vector.so
