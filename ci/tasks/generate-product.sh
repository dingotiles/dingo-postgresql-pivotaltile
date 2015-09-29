#!/bin/bash

subway_version=$(cat cf-subway-boshrelease/version)
cp -r cf-subway-boshrelease/release.tgz tile/releases/cf-subway-boshrelease-${subway_version}.tgz

docker_version=$(cat docker-boshrelease/version)
cp -r docker-boshrelease/release.tgz tile/releases/docker-boshrelease-${docker_version}.tgz

pg_docker_version=$(cat postgresql-docker-boshrelease/version)
cp -r postgresql-docker-boshrelease/release.tgz tile/releases/postgresql-docker-boshrelease-${pg_docker_version}.tgz

cd tile
ls -al releases/

echo "creating .pivotal file"

zip -r postgresql-docker.pivotal content_migrations metadata releases
