#!/bin/bash

set -e

sudo mv /usr/bin/spruce /usr/bin/spruce-dir
sudo mv /usr/bin/spruce-dir/spruce /usr/bin/spruce
sudo chmod 755 /usr/bin/spruce
spruce -v

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# this script is run assuming repo stored in folder 'tile'

mkdir -p tile/generated/releases

subway_version=$(cat cf-subway-boshrelease/version)
cp -r cf-subway-boshrelease/release.tgz tile/generated/releases/cf-subway-boshrelease-${subway_version}.tgz

docker_version=$(cat docker-boshrelease/version)
cp -r docker-boshrelease/release.tgz tile/generated/releases/docker-boshrelease-${docker_version}.tgz

pg_docker_version=$(cat postgresql-docker-boshrelease/version)
cp -r postgresql-docker-boshrelease/release.tgz tile/generated/releases/postgresql-docker-boshrelease-${pg_docker_version}.tgz

cat >tile/templates/metadata/releases.yml <<EOF
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
  templates/metadata/base.yml > generated/metadata/postgresql-docker.yml

cd generated

echo "creating .pivotal file"
zip -r postgresql-docker.pivotal content_migrations metadata releases

cd $DIR/../..

git config --global user.email "concourse-bot@ge.com"
git config --global user.name "Concourse Bot"

echo "Checking for changes in $(pwd)..."
if [[ "$(git status -s)X" != "X" ]]; then
  git add . --all
  git commit -m "New bosh release versions"
fi
