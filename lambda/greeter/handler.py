"""
Greeter Lambda
--------------
Triggered by GET /greet (API Gateway HTTP API).
1. Writes a record to the regional DynamoDB GreetingLogs table.
2. Publishes a verification payload to the Unleash Live SNS topic (us-east-1).
3. Returns 200 with the executing region name.
"""

import json
import os
import uuid
from datetime import datetime, timezone

import boto3


def handler(event, context):
    region = os.environ["AWS_REGION"]
    table_name = os.environ["DYNAMODB_TABLE"]
    sns_topic_arn = os.environ["SNS_TOPIC_ARN"]
    email = os.environ["EMAIL"]
    repo_url = os.environ["REPO_URL"]

    # --- Write greeting record to regional DynamoDB ---
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)

    record_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    table.put_item(
        Item={
            "id": record_id,
            "region": region,
            "timestamp": timestamp,
            "message": f"Hello from {region}",
        }
    )

    # --- Publish verification payload to us-east-1 SNS (cross-region safe) ---
    sns = boto3.client("sns", region_name="us-east-1")
    payload = {
        "email": email,
        "source": "Lambda",
        "region": region,
        "repo": repo_url,
    }
    sns.publish(
        TopicArn=sns_topic_arn,
        Message=json.dumps(payload),
        Subject=f"Greeter verification from {region}",
    )

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "message": f"Hello from {region}",
                "region": region,
                "recordId": record_id,
                "timestamp": timestamp,
            }
        ),
    }
