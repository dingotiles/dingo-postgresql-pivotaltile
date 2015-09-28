#!/bin/bash

set -x # print commands
set -e # fail fast

ls -la generated-tile/*
tile_path=generated-tile/postgresql-docker.pivotal

if [[ "${opsmgr_skip_ssl_verification}X" != "X" ]]; then
  skip_ssl="-k "
fi

curl -f ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/api_version"
echo

installation_guid=$(curl -f ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  ${opsmgr_url}/api/installation_settings/products | \
  jq -r '.[].installation_name | scan("^postgresql-docker-.*")')
echo

curl ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  ${opsmgr_url}/api/installation_settings/products/${installation_guid} \
  -d '' -X DELETE
echo

# there is no way to delete a specific product (the one being uploaded)
# so delete all products and hope for the best
curl -f ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products" -d '' -X DELETE
echo

curl -f -v ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products" -X POST -F "product[file]=@${tile_path}"
echo
