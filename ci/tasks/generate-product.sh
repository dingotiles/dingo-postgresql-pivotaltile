#!/bin/bash

set -e # fail fast

spruce -v

mkdir -p tile/tmp/metadata
mkdir -p tile/generated/metadata
mkdir -p tile/generated/releases
mkdir -p tile/generated/content_migrations

TILE_VERSION=$(cat tile-version/number)

broker_tgz_dir=release-tarball/boshrelease/releases/dingo-s3
broker_version=$(ls ${broker_tgz_dir}/dingo-s3-*tgz | sed "s#${broker_tgz_dir}/dingo-s3-\(.*\)\.tgz#\1#")
cp ${broker_tgz_dir}/dingo-s3-${broker_version}.tgz tile/generated/releases/

broker_registrar_version=$(cat broker-registrar-boshrelease/version)
cp -r broker-registrar-boshrelease/release.tgz tile/generated/releases/broker-registrar-${broker_registrar_version}.tgz

cd tile
cp -r resources generated/

if [[ "${OPSMGR_URL}X" == "X" ]]; then
  echo "upload-product.sh requires \$OPSMGR_URL, \$OPSMGR_USERNAME, \$OPSMGR_PASSWORD"
  exit 1
fi

if [[ "${OPSMGR_SKIP_SSL_VERIFICATION}X" != "X" ]]; then
  SKIP_SSL="-k "
fi
broker_prev_version=$(curl -f ${SKIP_SSL} -u ${OPSMGR_USERNAME}:${OPSMGR_PASSWORD} ${OPSMGR_URL}/api/installation_settings | jq -r ".products[] | select(.identifier == \"dingo-s3\") | .product_version")
if [[ "${broker_prev_version}X" == "X" ]]; then
  echo "Tile is not currently installed."
  # set $broker_prev_version to something; not important as tile not installed
  broker_prev_version=$TILE_VERSION
else
  echo "Current tile version '${broker_prev_version}' is installed"
fi

cat >tmp/metadata/version.yml <<EOF
---
product_version: "${TILE_VERSION}"
EOF

echo Looking up all previous versions to generate content_migrations/dingo-s3.yml
./ci/tasks/generate_content_migration.rb ${TILE_VERSION} generated/content_migrations/dingo-s3.yml

echo Migrations:
cat generated/content_migrations/dingo-s3.yml

cat >tmp/metadata/releases.yml <<EOF
---
releases:
- name: dingo-s3
  file: dingo-s3-${broker_version}.tgz
  version: "${broker_version}"
- name: broker-registrar
  file: broker-registrar-${broker_registrar_version}.tgz
  version: "${broker_registrar_version}"
EOF

spruce merge \
  tmp/metadata/version.yml \
  tmp/metadata/releases.yml \
  templates/metadata/form_types.yml \
  templates/metadata/property_blueprints.yml \
  templates/metadata/job_types.yml \
  templates/metadata/errands_broker_registrar.yml \
  templates/deploy_and_delete_errands.yml \
  templates/metadata/base.yml > generated/metadata/dingo-s3.yml


cd generated

echo "creating dingo-s3-${TILE_VERSION}.pivotal file"
zip -r dingo-s3-${TILE_VERSION}.pivotal content_migrations metadata releases

# output in tile/generated/dingo-s3-${TILE_VERSION}.pivotal
