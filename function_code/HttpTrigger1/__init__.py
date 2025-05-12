import logging
import os
import azure.functions as func

# Import Azure SDK clients
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.storage.blob import BlobServiceClient


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Python HTTP trigger function processed a request.")

    # Get configuration from App Settings
    key_vault_uri = os.environ.get("KEY_VAULT_URI")
    secret_name = os.environ.get("SECRET_NAME")
    storage_account_name = os.environ.get("STORAGE_ACCOUNT_NAME")

    if not key_vault_uri or not secret_name or not storage_account_name:
        logging.error(
            "Missing required environment variables: KEY_VAULT_URI, SECRET_NAME, or STORAGE_ACCOUNT_NAME"
        )
        return func.HttpResponse("Error: Missing configuration.", status_code=500)

    # Use DefaultAzureCredential which automatically uses the Function App's Managed Identity
    credential = DefaultAzureCredential()

    results = {}

    # 1. Test Key Vault Access
    try:
        logging.info(f"Attempting to connect to Key Vault: {key_vault_uri}")
        secret_client = SecretClient(vault_url=key_vault_uri, credential=credential)
        retrieved_secret = secret_client.get_secret(secret_name)
        results["key_vault_secret_value"] = retrieved_secret.value
        logging.info(f"Successfully retrieved secret '{secret_name}' from Key Vault.")
    except Exception as e:
        logging.error(f"Error accessing Key Vault: {e}", exc_info=True)
        results["key_vault_error"] = str(e)

    # 2. Test Storage Account Access
    try:
        storage_account_url = f"https://{storage_account_name}.blob.core.windows.net"
        logging.info(f"Attempting to connect to Storage Account: {storage_account_url}")
        blob_service_client = BlobServiceClient(
            account_url=storage_account_url, credential=credential
        )

        # List containers (requires 'Storage Blob Data Reader' or higher on the account level)
        # Or list blobs in a specific container if permissions are container-level
        container_client = blob_service_client.get_container_client(
            "$web"
        )  # Example: Check the static web container, or choose another one
        # Create container if it doesn't exist (requires Contributor role) - skip for read-only test
        # try:
        #    container_client.create_container()
        # except Exception:
        #    pass # Ignore if already exists

        blob_list = []
        logging.info(f"Listing blobs in container: {container_client.container_name}")
        blobs = container_client.list_blobs()
        for blob in blobs:
            blob_list.append(blob.name)

        results["storage_blobs"] = blob_list
        if not blob_list:
            results["storage_info"] = (
                f"No blobs found in container '{container_client.container_name}'."
            )
        logging.info(
            f"Successfully listed blobs from Storage Account container '{container_client.container_name}'."
        )

    except Exception as e:
        logging.error(f"Error accessing Storage Account: {e}", exc_info=True)
        results["storage_error"] = str(e)

    # Construct response
    response_message = f"Function executed. Results:\nKV Secret ({secret_name}): {results.get('key_vault_secret_value', 'ERROR - ' + results.get('key_vault_error', 'Unknown'))}\nStorage Blobs: {results.get('storage_blobs', 'ERROR - ' + results.get('storage_error', 'Unknown'))} {results.get('storage_info', '')}"

    return func.HttpResponse(response_message, status_code=200)
