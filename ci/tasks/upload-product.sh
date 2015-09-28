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

if [[ "${installation_guid}X" != "X" ]]; then
  curl ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
    ${opsmgr_url}/api/installation_settings/products/${installation_guid} \
    -d '' -X DELETE
  echo
fi

# start installation to delete /api/installation -X POST
# poll for status installation /api/installation -X GET
# fail if deletion failed (not {"status": "success"})

curl -f ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products"
echo

# there is no way to delete a specific product (the one being uploaded)
# so delete all products and hope for the best
curl -f ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products" -d '' -X DELETE
echo

curl -f ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products"
echo

echo Uploading the product
curl -f -v ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products" -X POST -F "product[file]=@${tile_path}"
echo

curl -f ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products"
echo

product_version=$(curl -f ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products" | jq -r ".[] | select(.name == \"postgresql-docker\") | .product_version")
echo

echo Adding the product to the installation
curl -f -v ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  ${opsmgr_url}/api/installation_settings/products -X POST \
    -d "name=postgresql-docker&product_version=${product_version}"

# add following to installation_settings (from microbosh)
# "singleton_availability_zone_reference": "ed202632256aa04465de",
# "network_reference": "a6691bc59528f242b122",
# "availability_zone_references": [
#   "ed202632256aa04465de"
# ],

# start installation /api/installation -X POST
# poll for status installation /api/installation -X GET
