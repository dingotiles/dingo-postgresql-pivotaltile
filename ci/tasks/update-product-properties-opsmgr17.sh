#!/bin/bash

set -e # fail fast

: ${opsmgr_url?}
: ${opsmgr_username?}
: ${opsmgr_password?}

insecure=
skip_ssl=
if [[ "${opsmgr_skip_ssl_verification}X" != "X" ]]; then
  insecure="-k"
  skip_ssl="--skip-ssl-validation"
fi

uaac target ${opsmgr_url}/uaa ${skip_ssl}
uaac token owner get opsman ${opsmgr_username} -s '' -p ${opsmgr_password}

access_token=$(uaac context admin | grep access_token | awk '{print $2}')

function info() {
  echo "$@ " >&2
}

function curl_auth() {
  info curl $@
  curl -f ${insecure} -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" $@
}

function curl_auth_quiet() {
  curl -sf ${insecure} -H "Content-Type: application/json" -H "Authorization: Bearer ${access_token}" $@
}

product_guid=$(curl_auth_quiet ${opsmgr_url}/api/v0/staged/products | \
  jq -r '.[] | select(.type == "dingo-postgresql") | .guid')
if [[ "${product_guid}X" == "X" ]]; then
  echo "Could not find dingo-postgresql tile"
  exit 1
fi

properties=$(curl_auth_quiet ${opsmgr_url}/api/v0/staged/products/${product_guid}/properties)
configurable_properties=($(echo $properties \
  | jq -r ".properties | with_entries(select(.value.configurable)) | keys[]"))

cat > tmp/install.yml <<EOS
---
properties:
EOS

cat > tmp/current_properties.yml <<EOS
---
configuration:
EOS

for property in "${configurable_properties[@]}"; do
  key=${property#.properties.}
  value=$(echo $properties| jq -r ".properties[\"${property}\"].value")
  cat >> tmp/current_properties.yml <<EOS
  ${key}: ${value}
EOS

  cat >> tmp/install.yml <<EOS
  "${property}":
    value: (( grab configuration.[${key}] ))
EOS
done

# if no configuration.yml provided then reuse existing configuration
if [[ ! -f tmp/configuration.yml ]]; then
  cp tmp/current_properties.yml tmp/configuration.yml
fi
spruce merge --prune configuration tmp/install.yml tmp/configuration.yml > tmp/properties.yml

api_data=$(cat tmp/properties.yml | yaml2json)

echo "Updating staged tile properties..."
curl_auth_quiet ${opsmgr_url}/api/v0/staged/products/${product_guid}/properties \
  -X PUT -d ${api_data}
