import logging
import json
import azure.functions as func
import time
import os

from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential
from azure.storage.blob import (
    BlobServiceClient,
    ContainerClient,
)  # Added for Blob Storage


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Python HTTP trigger function processed a request.")

    key_vault_uri = os.environ.get("KEY_VAULT_URI")
    if not key_vault_uri:
        return func.HttpResponse(
            json.dumps(
                {
                    "error": "Key Vault URI not provided.",
                    "details": "Please set the KEY_VAULT_URI environment variable.",
                }
            ),
            mimetype="application/json",
            status_code=500,
        )
    try:
        secret_name = req.params.get("secret")
        if not secret_name:
            return func.HttpResponse(
                json.dumps(
                    {
                        "error": "Secret name not provided.",
                        "details": "Please provide a secret name in the query parameters.",
                    }
                ),
                mimetype="application/json",
                status_code=400,
            )
        credential = DefaultAzureCredential()
        client = SecretClient(vault_url=key_vault_uri, credential=credential)
        secret = client.get_secret(secret_name)

    except Exception as e:
        logging.error(f"Failed in getting secrets: {e}")
        return func.HttpResponse(
            json.dumps({"error": "Failed in getting secrets.", "details": str(e)}),
            mimetype="application/json",
            status_code=500,
        )

    container_name = os.environ.get("CONTAINER_NAME")
    storage_account_name = os.environ.get("STORAGE_ACCOUNT_NAME")
    try:
        blob_service_url = f"https://{storage_account_name}.blob.core.windows.net"
        blob_service_client = BlobServiceClient(
            account_url=blob_service_url, credential=credential
        )
        container_client = blob_service_client.get_container_client(container_name)

        blobs_list = []
        blob_items = container_client.list_blobs()
        for blob_item in blob_items:
            blobs_list.append({"name": blob_item.name, "size": blob_item.size})

        logging.info(
            f"Successfully listed {len(blobs_list)} blobs from container '{container_name}'."
        )
        return func.HttpResponse(
            json.dumps(
                {
                    secret_name: secret.value,
                    "blobs": blobs_list,
                }
            ),
            mimetype="application/json",
            status_code=200,
        )

    except Exception as e:
        logging.error(f"Failed in getting blobs: {e}")
        return func.HttpResponse(
            json.dumps({"error": "Failed in getting blobs.", "details": str(e)}),
            mimetype="application/json",
            status_code=500,
        )
