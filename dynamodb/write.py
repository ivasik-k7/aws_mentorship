import json
import logging
from datetime import datetime

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")


def lambda_handler(event, context):
    """
    Writes items to DynamoDB with compatibility for paginated reads.

    Expected event format (single item):
    {
        "operation": "put_item",  # or "update_item", "delete_item", "batch_write"
        "table_name": "YourTableName",
        "item": {
            "partition_key": "value",
            "sort_key": "value",  # if composite key
            "attribute1": "value1",
            "attribute2": "value2",
            "created_at": "auto"  # special value for timestamp
        },
        "condition_expression": "attribute_not_exists(partition_key)"  # optional
    }

    OR (batch operations):
    {
        "operation": "batch_write",
        "table_name": "YourTableName",
        "items": [
            {
                "put_request": {
                    "item": { ... }
                }
            },
            {
                "delete_request": {
                    "key": { ... }
                }
            }
        ]
    }
    """
    try:
        if not event or "table_name" not in event or "operation" not in event:
            logger.error("Invalid input: table_name and operation are required")
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "table_name and operation are required"}),
            }

        operation = event["operation"]
        table_name = event["table_name"]
        table = dynamodb.Table(table_name)

        if operation == "put_item":
            return handle_put_item(table, event)
        elif operation == "update_item":
            return handle_update_item(table, event)
        elif operation == "delete_item":
            return handle_delete_item(table, event)
        elif operation == "batch_write":
            return handle_batch_write(dynamodb, event)
        else:
            logger.error(f"Invalid operation: {operation}")
            return {
                "statusCode": 400,
                "body": json.dumps({"error": f"Invalid operation: {operation}"}),
            }

    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        error_message = e.response["Error"]["Message"]
        logger.error(f"DynamoDB ClientError ({error_code}): {error_message}")

        status_code = 500
        if error_code == "ConditionalCheckFailedException":
            status_code = 409
        elif error_code == "ValidationException":
            status_code = 400

        return {"statusCode": status_code, "body": json.dumps({"error": error_message})}
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Internal server error"}),
        }


def handle_put_item(table, event):
    if "item" not in event:
        logger.error("PutItem operation requires 'item' parameter")
        return {
            "statusCode": 400,
            "body": json.dumps(
                {"error": "PutItem operation requires 'item' parameter"}
            ),
        }

    item = process_item(event["item"])
    condition_expression = event.get("condition_expression")

    put_params = {"Item": item}
    if condition_expression:
        put_params["ConditionExpression"] = condition_expression

    response = table.put_item(**put_params)

    logger.info("Successfully put item")
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "operation": "put_item",
                "success": True,
                "item": item,
                "response_metadata": response.get("ResponseMetadata", {}),
            }
        ),
    }


def handle_update_item(table, event):
    if "key" not in event or "update_expression" not in event:
        logger.error("UpdateItem operation requires 'key' and 'update_expression'")
        return {
            "statusCode": 400,
            "body": json.dumps(
                {"error": "UpdateItem requires 'key' and 'update_expression'"}
            ),
        }

    key = event["key"]
    update_expression = event["update_expression"]
    expression_values = event.get("expression_attribute_values", {})
    condition_expression = event.get("condition_expression")

    update_params = {
        "Key": key,
        "UpdateExpression": update_expression,
        "ExpressionAttributeValues": expression_values,
        "ReturnValues": "ALL_NEW",
    }

    if condition_expression:
        update_params["ConditionExpression"] = condition_expression

    response = table.update_item(**update_params)
    updated_item = response.get("Attributes", {})

    logger.info("Successfully updated item")
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "operation": "update_item",
                "success": True,
                "updated_item": updated_item,
                "response_metadata": response.get("ResponseMetadata", {}),
            }
        ),
    }


def handle_delete_item(table, event):
    if "key" not in event:
        logger.error("DeleteItem operation requires 'key' parameter")
        return {
            "statusCode": 400,
            "body": json.dumps(
                {"error": "DeleteItem operation requires 'key' parameter"}
            ),
        }

    key = event["key"]
    condition_expression = event.get("condition_expression")

    delete_params = {"Key": key}
    if condition_expression:
        delete_params["ConditionExpression"] = condition_expression

    response = table.delete_item(**delete_params)

    logger.info("Successfully deleted item")
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "operation": "delete_item",
                "success": True,
                "deleted_key": key,
                "response_metadata": response.get("ResponseMetadata", {}),
            }
        ),
    }


def handle_batch_write(dynamodb, event):
    if "items" not in event or not event["items"]:
        logger.error("BatchWrite operation requires 'items' parameter")
        return {
            "statusCode": 400,
            "body": json.dumps(
                {"error": "BatchWrite operation requires 'items' parameter"}
            ),
        }

    table_name = event["table_name"]
    processed_items = []

    batch_items = event["items"][:25]

    for item in batch_items:
        if "put_request" in item and "item" in item["put_request"]:
            item["put_request"]["item"] = process_item(item["put_request"]["item"])
            processed_items.append(item)
        else:
            processed_items.append(item)

    response = dynamodb.batch_write_item(RequestItems={table_name: processed_items})

    unprocessed_items = response.get("UnprocessedItems", {}).get(table_name, [])

    logger.info(
        f"Batch write completed with {len(unprocessed_items)} unprocessed items"
    )
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "operation": "batch_write",
                "success": True,
                "processed_count": len(batch_items) - len(unprocessed_items),
                "unprocessed_items": unprocessed_items,
                "response_metadata": response.get("ResponseMetadata", {}),
            }
        ),
    }


def process_item(item):
    processed = item.copy()

    # Handle automatic timestamps
    for key, value in processed.items():
        if value == "auto":
            if key.endswith("_at") or key.endswith("_timestamp"):
                processed[key] = datetime.utcnow().isoformat()
            elif key.endswith("_date"):
                processed[key] = datetime.utcnow().date().isoformat()

    return processed
