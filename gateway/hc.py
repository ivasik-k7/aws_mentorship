import json


def lambda_handler(event, context):
    # Perform health check logic here (e.g., checking a database or an API)
    try:
        # Example of a health check (replace with your own check logic)
        health_status = "Healthy"  # This could be a result from an API/database query
        status_code = 200  # HTTP status code for success
    except Exception as e:
        health_status = f"Unhealthy: {str(e)}"
        status_code = 500

    # Return the response
    return {
        "statusCode": status_code,
        "body": json.dumps(
            {
                "status": health_status,
                "message": "Health check completed successfully"
                if status_code == 200
                else "Health check failed",
            }
        ),
    }
