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
  curl -f ${insecure} -H "Authorization: Bearer ${access_token}" $@
}

function curl_auth_quiet() {
  curl -sf ${insecure} -H "Authorization: Bearer ${access_token}" $@
}

product_guid=$(curl_auth_quiet ${opsmgr_url}/api/v0/staged/products | \
  jq -r '.[] | select(.type == "dingo-postgresql") | .guid')
if [[ "${product_guid}X" == "X" ]]; then
  echo "Could not find dingo-postgresql tile"
  exit 1
fi

configurable_properties=($(curl_auth_quiet ${opsmgr_url}/api/v0/staged/products/${product_guid}/properties \
  | jq -r ".properties | with_entries(select(.value.configurable)) | keys[]"))

cat > tmp/install.yml <<EOS
---
properties:
EOS

for property in "${configurable_properties[@]}"; do
  echo $property
  cat >> tmp/install.yml <<EOS
  "${property}":
    value: (( grab ${property} ))
EOS
done

cat tmp/install.yml
