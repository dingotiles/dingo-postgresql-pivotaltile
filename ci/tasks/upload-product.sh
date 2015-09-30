#!/bin/bash

set -x # print commands
set -e # fail fast

if [[ "${opsmgr_url}X" == "X" ]]; then
  echo "upload-product.sh requires \$opsmgr_url, \$opsmgr_username, \$opsmgr_password"
  exit
fi

tile_path=generated-tile/postgresql-docker.pivotal

if [[ "${opsmgr_skip_ssl_verification}X" != "X" ]]; then
  skip_ssl="-k "
fi

echo Uploading the product
curl -f ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products" -X POST -F "product[file]=@${tile_path}"
echo

curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products"
echo

product_version=$(curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products" | jq -r ".[] | select(.name == \"postgresql-docker\") | .product_version")
echo

echo Adding the product to the installation
curl -f ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  ${opsmgr_url}/api/installation_settings/products -X POST \
    -d "name=postgresql-docker&product_version=${product_version}"
echo

echo Setting AZ for installation to same as microbosh
microbosh_az_id=$(curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  ${opsmgr_url}/api/installation_settings | jq -r ".products[0].singleton_availability_zone_reference")
# add following to installation_settings (from microbosh)
# "singleton_availability_zone_reference": "ed202632256aa04465de",
# "network_reference": "a6691bc59528f242b122",
# "availability_zone_references": [
#   "ed202632256aa04465de"
# ],

products_count=$(curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  ${opsmgr_url}/api/installation_settings | \
  jq -r ".products | length")
product_index=$(expr $products_count - 1)

curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  ${opsmgr_url}/api/installation_settings | \
  jq ".products[${product_index}].singleton_availability_zone_reference = \"${microbosh_az_id}\" | .products[${product_index}].availability_zone_references = [\"${microbosh_az_id}\"]" \
  > installation_settings.json
echo

curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  ${opsmgr_url}/api/installation_settings -X POST \
    -F 'installation[file]=@installation_settings.json'
echo

echo "Installing product"

echo "Running installation process"
response=$(curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/installation?ignore_warnings=1" -d '' -X POST)
installation_id=$(echo $response | jq -r .install.id)

set +x # silence print commands
status=running
prevlogslength=0
until [[ "${status}" != "running" ]]; do
  sleep 1
  status_json=$(curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
    "${opsmgr_url}/api/installation/${installation_id}")
  status=$(echo $status_json | jq -r .status)
  if [[ "${status}X" == "X" || "${status}" == "failed" ]]; then
    installation_exit=1
  fi

  logs=$(curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
    ${opsmgr_url}/api/installation/${installation_id}/logs | jq -r .logs)
  if [[ "${logs:${prevlogslength}}" != "" ]]; then
    echo -n ${logs:${prevlogslength}}
    prevlogslength=${#logs}
  fi
done
echo $status_json

if [[ "${installation_exit}X" != "X" ]]; then
  exit ${installation_exit}
fi
