#!/bin/bash

set -x # print commands
set -e # fail fast

if [[ "${opsmgr_url}X" == "X" ]]; then
  echo "delete-product.sh requires \$opsmgr_url, \$opsmgr_username, \$opsmgr_password"
  exit
fi

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
    status=$(echo $status_json | jq -r .status)
    if [[ "${status}X" == "X" || "${status}" == "failed" ]]; then
      installation_exit=1
    fi

    logs=$(curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
      ${opsmgr_url}/api/installation/${installation_id}/logs | jq -r .logs)
    if [[ "${logs:${prevlogslength}}" != "" ]]; then
      echo -e ${logs:${prevlogslength}}
      prevlogslength=${#logs}
    fi
  done
  echo $status_json

  if [[ "${installation_exit}X" != "X" ]]; then
    exit ${installation_exit}
  fi
done

curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products"
echo

# there is no way to delete a specific product (the one being uploaded)
# so delete all products and hope for the best
curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products" -d '' -X DELETE
echo

curl -sf ${skip_ssl} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/products"
echo
