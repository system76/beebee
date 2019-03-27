# Dockerfile
# A production grade docker image for beebee.

FROM elixir:1.8.1-alpine as build
MAINTAINER Blake Kostner

RUN mkdir /app

COPY . /app

ENV APP_NAME=beebee
ENV MIX_ENV=prod

RUN apk add --no-cache gcc git make musl-dev

RUN cd /app && \
  mix local.hex --force && \
  mix local.rebar --force && \
  mix deps.get && \
  mix release

RUN export RELEASE_DIR=`ls -d /app/_build/prod/rel/$APP_NAME/releases/*/` && \
  mkdir /export && \
  tar -xf "$RELEASE_DIR/$APP_NAME.tar.gz" -C /export

FROM elixir:1.8.1-alpine as release

RUN apk add --no-cache bash

WORKDIR /opt/beebee

COPY --from=build /export/ /opt/beebee

RUN touch /etc/beebee.toml

ENTRYPOINT ["/opt/beebee/bin/beebee"]
CMD ["foreground"]
