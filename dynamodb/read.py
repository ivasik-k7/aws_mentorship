import json
import logging

import boto3
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB client
dynamodb = boto3.resource("dynamodb")


def lambda_handler(event, context):
    """
    Reads paginated items from DynamoDB table with proper query/scan handling.

    For QUERY operations (requires key conditions):
    {
        "table_name": "YourTableName",
        "operation": "query",
        "key_condition_expression": "partition_key = :pk AND begins_with(sort_key, :sk)",
        "expression_attribute_values": {
            ":pk": "partition_value",
            ":sk": "sort_prefix"
        },
        "limit": 10,
        "exclusive_start_key": { ... },
        "projection_expression": "attr1, attr2",
        "scan_index_forward": false
    }

    For SCAN operations (full table scan):
    {
        "table_name": "YourTableName",
        "operation": "scan",
        "filter_expression": "attribute_name = :value",
        "expression_attribute_values": {
            ":value": "some_value"
        },
        "limit": 10,
        "exclusive_start_key": { ... },
        "projection_expression": "attr1, attr2"
    }
    """
    try:
        if not event or "table_name" not in event:
            logger.error("Invalid input: table_name is required")
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "table_name is required"}),
            }

        table_name = event["table_name"]
        operation = event.get("operation", "scan")  # Default to scan if not specified
        limit = event.get("limit", 10)
        exclusive_start_key = event.get("exclusive_start_key")
        projection_expression = event.get("projection_expression")

        logger.info(f"Reading items from table {table_name} with operation {operation}")

        table = dynamodb.Table(table_name)

        params = {"Limit": limit, "ConsistentRead": event.get("consistent_read", False)}

        if exclusive_start_key:
            params["ExclusiveStartKey"] = exclusive_start_key
        if projection_expression:
            params["ProjectionExpression"] = projection_expression

        if operation.lower() == "query":
            if "key_condition_expression" not in event:
                logger.error("Query operation requires key_condition_expression")
                return {
                    "statusCode": 400,
                    "body": json.dumps(
                        {"error": "Query operation requires key_condition_expression"}
                    ),
                }

            params["KeyConditionExpression"] = event["key_condition_expression"]

            if "expression_attribute_values" in event:
                params["ExpressionAttributeValues"] = event[
                    "expression_attribute_values"
                ]
            if "expression_attribute_names" in event:
                params["ExpressionAttributeNames"] = event["expression_attribute_names"]

            if "scan_index_forward" in event:
                params["ScanIndexForward"] = event["scan_index_forward"]

            response = table.query(**params)
        else:  # Default to scan
            if "filter_expression" in event:
                params["FilterExpression"] = event["filter_expression"]
                if "expression_attribute_values" in event:
                    params["ExpressionAttributeValues"] = event[
                        "expression_attribute_values"
                    ]
                if "expression_attribute_names" in event:
                    params["ExpressionAttributeNames"] = event[
                        "expression_attribute_names"
                    ]

            response = table.scan(**params)

        items = response.get("Items", [])
        last_evaluated_key = response.get("LastEvaluatedKey")

        logger.info(f"Successfully retrieved {len(items)} items")

        response_data = {
            "operation": operation,
            "items": items,
            "count": len(items),
            "scanned_count": response.get("ScannedCount", len(items)),
            "last_evaluated_key": last_evaluated_key,
            "has_more": last_evaluated_key is not None,
        }

        return {
            "statusCode": 200,
            "body": json.dumps(response_data, default=str),  # Handle datetime objects
        }

    except ClientError as e:
        logger.error(f"DynamoDB ClientError: {e.response['Error']['Message']}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": e.response["Error"]["Message"]}),
        }
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Internal server error"}),
        }
