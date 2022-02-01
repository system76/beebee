
FROM elixir:1.13-alpine AS builder

RUN apk add --no-cache git openssh-client

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

FROM alpine:3.12

# These are fed in from the build script
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

LABEL \
  org.opencontainers.image.created="${BUILD_DATE}" \
  org.opencontainers.image.description="URL shortener for http://s76.co" \
  org.opencontainers.image.revision="${VCS_REF}" \
  org.opencontainers.image.source="https://github.com/pop-os/warehouse" \
  org.opencontainers.image.title="beebee" \
  org.opencontainers.image.vendor="system76" \
  org.opencontainers.image.version="${VERSION}"

RUN apk update && \
  apk add --no-cache \
  git \
  bash \
  libgcc \
  libstdc++ \
  ca-certificates \
  ncurses-libs \
  openssl

RUN addgroup -S beebee && adduser -S beebee -G beebee

COPY --from=builder /tmp/beebee/_build/prod/rel/beebee ./

RUN chown -R beebee:beebee bin/beebee releases/
RUN chown -R beebee:beebee `ls | grep 'erts-'`/

USER beebee

EXPOSE 4000

ENTRYPOINT [ "bin/beebee" ]
CMD ["start" ]
