#!/bin/bash

buildah build \
  --build-arg VCS_REF="local" \
  --build-arg BUILD_DATE="local" \
  --build-arg VERSION="local" \
  --tag beebee .

podman container rm --force --ignore "beebee-beebee"
podman run --detach --pod beebee --name "beebee-beebee" beebee
