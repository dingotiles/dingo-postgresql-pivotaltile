#!/bin/bash

set -e # fail fast
set -x # print commands

TILE_VERSION=$(cat tile-version/number)

mkdir -p product/releases/

cat >tile/templates/metadata/releases.yml <<YAML
---
releases:
YAML

boshreleases=("patroni-docker" "etcd" "remote-syslog" "broker-registrar")
for boshrelease in "${boshreleases[@]}"
do
  release_version=$(cat ${boshrelease}/version)
  cat >>tile/templates/metadata/releases.yml <<YAML
  - name: ${boshrelease}
    file: ${boshrelease}-${release_version}.tgz
    version: "${release_version}"
YAML
  ls -al ${boshrelease}/
  if [[ -f ${boshrelease}/release.tgz ]]; then
    cp ${boshrelease}/release.tgz product/releases/${boshrelease}-${release_version}.tgz
  fi
done

cat tile/templates/metadata/releases.yml
ls product/releases/
