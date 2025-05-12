# HttpTrigger/__init__.py
import logging
import json
import azure.functions as func
import time


# Define the main function that Azure Functions will call
def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    Handles HTTP requests and returns a simple JSON response.

    Args:
        req: The incoming HTTP request object.

    Returns:
        An HTTP response object with a JSON body.
    """
    logging.info("Python HTTP trigger function processed a request.")

    # Get the 'name' query parameter, if provided
    name = req.params.get("name")
    if not name:
        try:
            # Try to get 'name' from the request body if not in query params
            req_body = req.get_json()
        except ValueError:
            # Ignore JSON decoding errors if the body is not JSON
            pass
        else:
            name = req_body.get("name")

    # Prepare the JSON data to return
    response_data = {
        "message": "Hello from the Azure Function!",
        "timestamp": time.time(),
    }

    # Personalize the message if a name was provided
    if name:
        response_data["message"] = (
            f"Hello, {name}! This HTTP triggered function executed successfully."
        )
        # Return a successful response with the personalized message
        return func.HttpResponse(
            json.dumps(response_data),  # Serialize the dictionary to a JSON string
            mimetype="application/json",
            status_code=200,
        )
    else:
        # Return a successful response with the default message
        return func.HttpResponse(
            json.dumps(response_data),  # Serialize the dictionary to a JSON string
            mimetype="application/json",
            status_code=200,
        )
