#!/bin/bash

if [ "$(terraform output -json enable_storage_acc_public_network_access)" ]; then
  eval "$(terraform output -raw enable_storage_acc_public_network_access)"
fi

if [ "$(terraform output -json enable_vault_public_network_access)" ]; then
  eval "$(terraform output -raw enable_vault_public_network_access)"
fi

if [ "$(terraform output -json enable_function_app_public_network_access)" ]; then
  eval "$(terraform output -raw enable_function_app_public_network_access)"
fi

terraform destroy -auto-approve
