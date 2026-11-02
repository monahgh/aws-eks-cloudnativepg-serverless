"""Audit handler: forwards EventBridge events to the SNS audit topic."""

import json
import os

import boto3

sns = boto3.client("sns")


def lambda_handler(event, context):
    detail = event.get("detail", {})
    subject = f"[audit] {event.get('detail-type', 'event')}"[:100]
    message = {
        "source": event.get("source"),
        "time": event.get("time"),
        "resources": event.get("resources", []),
        "message": detail.get("Message"),
        "event_id": detail.get("EventID"),
    }

    sns.publish(
        TopicArn=os.environ["SNS_TOPIC_ARN"],
        Subject=subject,
        Message=json.dumps(message, indent=2),
    )
    return {"published": True}
