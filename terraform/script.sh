#!/bin/bash
terraform apply -auto-approve
func_app_name=$(terraform output -raw function_app_name)
cd "./func_code" || exit
func azure functionapp publish "$func_app_name" --python
cd ..
eval "$(terraform output -raw disable_function_app_public_network_access)"
eval "$(terraform output -raw disable_storage_acc_public_network_access)"
eval "$(terraform output -raw disable_vault_public_network_access)"
func_address=$(terraform output -raw func_address)
echo "========================="
echo "Function App Address: $func_address"
echo "========================="
