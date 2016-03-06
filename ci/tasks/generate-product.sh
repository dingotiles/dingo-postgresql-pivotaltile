#!/bin/bash

set -e # fail fast
set -x # print commands

TILE_VERSION=$(cat tile-version/number)

mkdir -p tile/tmp/metadata
mkdir -p workspace/metadata
mkdir -p workspace/releases
mkdir -p workspace/content_migrations

cat >tile/tmp/metadata/version.yml <<EOF
---
product_version: "${TILE_VERSION}"
EOF

cat >tile/tmp/metadata/releases.yml <<YAML
---
releases:
YAML

boshreleases=("patroni-docker" "etcd" "remote-syslog" "broker-registrar")
for boshrelease in "${boshreleases[@]}"
do
  release_version=$(cat ${boshrelease}/version)
  cat >>tile/tmp/metadata/releases.yml <<YAML
  - name: ${boshrelease}
    file: ${boshrelease}-${release_version}.tgz
    version: "${release_version}"
YAML
  if [[ -f ${boshrelease}/release.tgz ]]; then
    cp ${boshrelease}/release.tgz product/releases/${boshrelease}-${release_version}.tgz
  fi
  if [[ -f ${boshrelease}/${boshrelease}-${release_version}.tgz ]]; then
    cp ${boshrelease}/${boshrelease}-${release_version}.tgz product/releases/
  fi
done

spruce merge \
  tile/tmp/metadata/version.yml \
  tile/tmp/metadata/releases.yml \
  tile/templates/metadata/form_types.yml \
  tile/templates/metadata/property_blueprints.yml \
  tile/templates/metadata/job_types.yml \
  tile/templates/metadata/errands_broker_registrar.yml \
  tile/templates/deploy_and_delete_errands.yml \
  tile/templates/metadata/base.yml > workspace/metadata/dingo-postgresql.yml


cd workspace
ls -laR .

echo "creating dingo-postgresql-${TILE_VERSION}.pivotal file"
zip -r dingo-postgresql-${TILE_VERSION}.pivotal content_migrations metadata releases

mv dingo-postgresql-${TILE_VERSION}.pivotal ../product
