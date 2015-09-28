#!/bin/bash

set -x # print commands
set -e # fail fast

# install dependencies
if [[ -x "$(command -v apt-get)" ]]; then
  sudo apt-get update
  sudo apt-get install -y curl
fi

ls -la generated-tile/*
tile_path=generated-tile/postgresql-docker.pivotal

if [[ "${opsmgr_skip_ssl_verification}X" != "X" ]]; then
  skip_ssl="-k "
fi

function _curl() {
  curl ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} $@
}

_curl "${opsmgr_url}/api/api_version"
echo

# there is no way to delete a specific product (the one being uploaded)
# so delete all products and hope for the best
_curl "${opsmgr_url}/api/products" -d '' -X DELETE
echo

_curl "${opsmgr_url}/api/products" -X POST -F "product[file]=@${tile_path}"
echo
