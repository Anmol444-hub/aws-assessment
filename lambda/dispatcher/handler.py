"""
Dispatcher Lambda
-----------------
Triggered by POST /dispatch (API Gateway HTTP API).
Calls ECS RunTask to launch a standalone Fargate task that publishes
the verification payload to the Unleash Live SNS topic and then exits.
"""

import json
import os

import boto3


def handler(event, context):
    region = os.environ["AWS_REGION"]
    cluster_arn = os.environ["ECS_CLUSTER_ARN"]
    task_def_arn = os.environ["ECS_TASK_DEFINITION_ARN"]
    subnet_id = os.environ["SUBNET_ID"]
    security_group_id = os.environ["SECURITY_GROUP_ID"]

    ecs = boto3.client("ecs", region_name=region)

    response = ecs.run_task(
        cluster=cluster_arn,
        taskDefinition=task_def_arn,
        launchType="FARGATE",
        networkConfiguration={
            "awsvpcConfiguration": {
                "subnets": [subnet_id],
                "securityGroups": [security_group_id],
                # Public IP required so the task can reach SNS without a NAT Gateway
                "assignPublicIp": "ENABLED",
            }
        },
    )

    failures = response.get("failures", [])
    if failures:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(
                {
                    "message": f"ECS RunTask failed in {region}",
                    "region": region,
                    "failures": failures,
                }
            ),
        }

    tasks = response.get("tasks", [])
    task_arn = tasks[0]["taskArn"] if tasks else None

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "message": f"ECS task dispatched in {region}",
                "region": region,
                "taskArn": task_arn,
            }
        ),
    }
