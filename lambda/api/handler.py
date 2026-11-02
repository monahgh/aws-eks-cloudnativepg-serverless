"""HTTP API + ingestion handler (scaffold).

Routes:
  GET  /health  -> liveness check
  POST /ingest  -> accepts a JSON payload for ingestion

The database write is a TODO: bundle a pure-Python driver (e.g. pg8000) in this
directory or a Lambda layer, then read credentials from DB_SECRET_ARN.
"""

import json
import os


def _response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    path = event.get("rawPath", "/")

    if method == "GET" and path == "/health":
        return _response(200, {"status": "ok", "db_host": os.environ.get("DB_HOST")})

    if method == "POST" and path == "/ingest":
        try:
            payload = json.loads(event.get("body") or "{}")
        except json.JSONDecodeError:
            return _response(400, {"error": "invalid JSON"})
        # TODO: insert payload into PostgreSQL using the secret in DB_SECRET_ARN.
        return _response(202, {"accepted": True, "keys": sorted(payload)})

    return _response(404, {"error": "not found"})
