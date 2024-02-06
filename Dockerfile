FROM elixir:1.13.1-slim AS builder

# Install dependencies
RUN set -xe; \
    apt-get update && apt-get install -y \
        build-essential \
        ca-certificates \
        git \
        openssh-client;

WORKDIR /tmp/beebee

ADD mix.exs .
ADD mix.lock .

RUN mix local.hex --force && \
  mix local.rebar --force && \
  MIX_ENV=prod mix deps.get && \
  MIX_ENV=prod mix deps.compile

# Do not copy _build or it will break the container build
COPY config ./config
COPY lib ./lib
COPY rel ./rel

RUN MIX_ENV=prod mix release

FROM debian:11.6-slim

# These are fed in from the build script
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

LABEL \
  org.opencontainers.image.created="${BUILD_DATE}" \
  org.opencontainers.image.description="URL shortener for http://s76.co" \
  org.opencontainers.image.revision="${VCS_REF}" \
  org.opencontainers.image.source="https://github.com/system76/beebee" \
  org.opencontainers.image.title="beebee" \
  org.opencontainers.image.vendor="system76" \
  org.opencontainers.image.version="${VERSION}"

RUN set -xe; \
    apt-get update && apt-get install -y \
        ca-certificates \
        libmcrypt4 \
        openssl;

RUN set -xe; \
    adduser --uid 1000 --system --home /beebee --shell /bin/sh --group beebee;

COPY --from=builder /tmp/beebee/_build/prod/rel/beebee ./

RUN chown -R beebee:beebee bin/beebee releases/
RUN chown -R beebee:beebee `ls | grep 'erts-'`/

ENV LANG=C.UTF-8

USER beebee

EXPOSE 4000

ENTRYPOINT [ "bin/beebee" ]
CMD ["start" ]
