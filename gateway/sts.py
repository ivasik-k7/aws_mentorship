import json

import boto3
from botocore.exceptions import ClientError


def lambda_handler(event, context):
    sts_client = boto3.client("sts")

    try:
        response = sts_client.get_caller_identity()

        user_arn = response.get("Arn")
        user_account = response.get("Account")
        user_id = response.get("UserId")

        health_status = "Healthy"
        status_code = 200
        identity_info = {"Arn": user_arn, "Account": user_account, "UserId": user_id}

    except ClientError as e:
        health_status = f"Unhealthy: {e.response['Error']['Message']}"
        status_code = 500
        identity_info = {}

    return {
        "statusCode": status_code,
        "body": json.dumps(
            {
                "status": health_status,
                "message": "Identity check completed successfully"
                if status_code == 200
                else "Identity check failed",
                "identity_info": identity_info,
            }
        ),
    }
