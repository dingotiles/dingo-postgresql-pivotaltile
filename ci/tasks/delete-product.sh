#!/bin/bash

set -x # print commands
set -e # fail fast

if [[ "${opsmgr_skip_ssl_verification}X" != "X" ]]; then
  skip_ssl="-k "
fi

curl -f ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/api_version"
echo

installation_guid=$(curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  ${opsmgr_url}/api/installation_settings/products | \
  jq -r '.[].installation_name | scan("^postgresql-docker-.*")')
echo

if [[ "${installation_guid}X" != "X" ]]; then
  echo "Product already installed, requesting it be deleted"
  curl -f ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
    ${opsmgr_url}/api/installation_settings/products/${installation_guid} \
    -d '' -X DELETE
  echo

  echo "Running installation to complete the deletion"
  response=$(curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
    "${opsmgr_url}/api/installation?ignore_warnings=1" -d '' -X POST)
  installation_id=$(echo $response | jq -r .install.id)

  set +x # silence print commands
  status=running
  until [[ "${status}" != "running" ]]; do
    sleep 10
    status_json=$(curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
      "${opsmgr_url}/api/installation/${installation_id}")
    echo $status_json
    status=$(echo $status_json | jq -r .status)
    if [[ "${status}X" == "X" ]]; then
      exit 1
    fi
  done
  set -x # print commands
fi
