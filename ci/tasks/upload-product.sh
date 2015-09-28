#!/bin/bash

set -x # print commands
set -e # fail fast

ls -la generated-tile/*
tile_path=generated-tile/*.pivotal

if [[ "${opsmgr_skip_ssl_verification}X" != "X" ]]; then
  skip_ssl="-k "
fi

function _curl() {
  curl ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} $@
}

_curl "${opsmgr_url}/api/api_version"

# there is no way to delete a specific product (the one being uploaded)
# so delete all products and hope for the best
_curl "${opsmgr_url}/api/products" -d '' -X DELETE

_curl "${opsmgr_url}/api/products" -X POST -F "product[file]=@${tile_path}"
