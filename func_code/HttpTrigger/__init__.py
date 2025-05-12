import logging
import json
import azure.functions as func
import time
import os

from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential


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

        return func.HttpResponse(
            json.dumps(
                {
                    "message": f"Secret '{secret_name}' retrieved successfully.",
                    "value": secret.value,
                }
            ),
            mimetype="application/json",
            status_code=200,
        )
    except Exception as e:
        logging.error(f"Failed to create DefaultAzureCredential: {e}")
        return func.HttpResponse(
            json.dumps(
                {"error": "Failed to create DefaultAzureCredential.", "details": str(e)}
            ),
            mimetype="application/json",
            status_code=500,
        )

    # # Get the 'name' query parameter, if provided
    # name = req.params.get("name")
    # if not name:
    #     try:
    #         # Try to get 'name' from the request body if not in query params
    #         req_body = req.get_json()
    #     except ValueError:
    #         # Ignore JSON decoding errors if the body is not JSON
    #         pass
    #     else:
    #         name = req_body.get("name")

    # # Prepare the JSON data to return
    # response_data = {
    #     "message": "Hello from the Azure Function!",
    #     "timestamp": time.time(),
    #     "xd": "xd",
    # }

    # # Personalize the message if a name was provided
    # if name:
    #     response_data["message"] = (
    #         f"Hello, {name}! This HTTP triggered function executed successfully."
    #     )
    #     # Return a successful response with the personalized message
    #     return func.HttpResponse(
    #         json.dumps(response_data),  # Serialize the dictionary to a JSON string
    #         mimetype="application/json",
    #         status_code=200,
    #     )
    # else:
    #     # Return a successful response with the default message
    #     return func.HttpResponse(
    #         json.dumps(response_data),  # Serialize the dictionary to a JSON string
    #         mimetype="application/json",
    #         status_code=200,
    #     )
