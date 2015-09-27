#!/bin/bash

# install dependencies
if [[ -x "$(command -v apt-get)" ]]; then
  sudo apt-get update
  sudo apt-get install -y zip
fi

docker_version=$(cat docker-boshrelease/version)
cp -r docker-boshrelease/release.tgz tile/releases/docker-release-${docker_version}.tgz

pg_docker_version=$(cat postgresql-docker-boshrelease/version)
cp -r postgresql-docker-boshrelease/release.tgz tile/releases/postgresql-docker-release-${pg_docker_version}.tgz

cd tile
ls -al releases/

echo "creating .pivotal file"

zip -r postgresql-docker.pivotal content_migrations metadata releases
