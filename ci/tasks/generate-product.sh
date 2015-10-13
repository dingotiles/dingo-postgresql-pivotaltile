#!/bin/bash

set -e

spruce -v

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}/../..

# this script is run assuming repo stored in folder 'tile'

mkdir -p generated/releases

if [[ "${local_dev}X" != "X" ]]; then
  subway_version=1
  docker_version=2
  pg_docker_version=3
else
  subway_version=$(cat tmp/releases/cf-subway-boshrelease/version)
  cp -r cf-subway-boshrelease/release.tgz generated/releases/cf-subway-boshrelease-${subway_version}.tgz

  docker_version=$(cat tmp/releases/docker-boshrelease/version)
  cp -r docker-boshrelease/release.tgz generated/releases/docker-boshrelease-${docker_version}.tgz

  pg_docker_version=$(cat tmp/releases/postgresql-docker-boshrelease/version)
  cp -r postgresql-docker-boshrelease/release.tgz generated/releases/postgresql-docker-boshrelease-${pg_docker_version}.tgz
fi

cat >templates/metadata/releases.yml <<EOF
---
releases:
- name: docker
  file: docker-boshrelease-${docker_version}.tgz
  version: "${docker_version}"
- name: cf-subway
  file: cf-subway-boshrelease-${subway_version}.tgz
  version: "${subway_version}"
- name: postgresql-docker
  file: postgresql-docker-boshrelease-${pg_docker_version}.tgz
  version: "${pg_docker_version}"
EOF

# all remaining references are relative to root of this repo
cd $DIR/../..
spruce merge \
  templates/metadata/releases.yml \
  templates/metadata/form_types.yml \
  templates/metadata/property_blueprints.yml \
  templates/metadata/job_types.yml \
  templates/metadata/service_plans.yml \
  templates/metadata/base.yml > generated/metadata/postgresql-docker.yml

cd generated

echo "creating .pivotal file"
zip -r postgresql-docker.pivotal content_migrations metadata releases

cd $DIR/../..

if [[ "${local_dev}X" == "X" ]]; then
  git config --global user.email "drnic+bot@starkandwayne.com"
  git config --global user.name "Concourse Bot"

  echo "Checking for changes in $(pwd)..."
  if [[ "$(git status -s)X" != "X" ]]; then
    git add . --all
    git commit -m "New bosh release versions"
  fi
fi
