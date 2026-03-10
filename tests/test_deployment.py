#!/usr/bin/env python3
"""
Unleash Live — automated multi-region deployment test
======================================================
Authenticates with Cognito, then concurrently exercises /greet and /dispatch
in both regions. Asserts that each response contains the correct region string
and prints measured latencies to highlight the geographic performance delta.

Usage
-----
    pip install boto3 httpx
    python tests/test_deployment.py \\
        --user-pool-id  us-east-1_XXXXXXXXX \\
        --client-id     <app-client-id> \\
        --username      you@example.com \\
        --password      YourP@ssword1 \\
        --us-east-1-url https://<id>.execute-api.us-east-1.amazonaws.com \\
        --eu-west-1-url https://<id>.execute-api.eu-west-1.amazonaws.com
"""

from __future__ import annotations

import argparse
import asyncio
import json
import sys
import time
from dataclasses import dataclass, field
from typing import Any, Optional

import boto3
import httpx
from botocore.exceptions import ClientError


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

@dataclass
class CallResult:
    label: str
    latency_ms: float
    status_code: Optional[int] = None
    body: Any = None
    error: Optional[str] = None
    expected_region: Optional[str] = None

    @property
    def ok(self) -> bool:
        return self.error is None and self.status_code == 200

    @property
    def region_matches(self) -> Optional[bool]:
        if self.expected_region is None or not isinstance(self.body, dict):
            return None
        return self.body.get("region") == self.expected_region


# ---------------------------------------------------------------------------
# Authentication
# ---------------------------------------------------------------------------

def authenticate(user_pool_id: str, client_id: str, username: str, password: str) -> str:
    """
    Authenticate with Cognito USER_PASSWORD_AUTH flow.
    Handles the NEW_PASSWORD_REQUIRED challenge that Cognito issues when a user
    created via the admin API logs in for the first time.
    Returns the IdToken (JWT) to use as the Authorization header.
    """
    client = boto3.client("cognito-idp", region_name="us-east-1")
    print(f"\n[AUTH] Authenticating '{username}' against pool '{user_pool_id}' …")

    try:
        resp = client.initiate_auth(
            AuthFlow="USER_PASSWORD_AUTH",
            AuthParameters={"USERNAME": username, "PASSWORD": password},
            ClientId=client_id,
        )
    except ClientError as exc:
        print(f"[AUTH] FAILED — {exc}")
        sys.exit(1)

    # First-time login: Cognito requires the user to set a permanent password.
    if resp.get("ChallengeName") == "NEW_PASSWORD_REQUIRED":
        print("[AUTH] NEW_PASSWORD_REQUIRED challenge — setting permanent password …")
        try:
            resp = client.respond_to_auth_challenge(
                ClientId=client_id,
                ChallengeName="NEW_PASSWORD_REQUIRED",
                Session=resp["Session"],
                ChallengeResponses={
                    "USERNAME": username,
                    "NEW_PASSWORD": password,
                },
            )
        except ClientError as exc:
            print(f"[AUTH] Challenge response FAILED — {exc}")
            sys.exit(1)

    token = resp["AuthenticationResult"]["IdToken"]
    print("[AUTH] OK — JWT obtained.")
    return token


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

async def call_endpoint(
    client: httpx.AsyncClient,
    url: str,
    token: str,
    method: str,
    label: str,
    expected_region: Optional[str] = None,
) -> CallResult:
    headers = {"Authorization": token, "Content-Type": "application/json"}
    t0 = time.perf_counter()
    try:
        if method.upper() == "GET":
            response = await client.get(url, headers=headers, timeout=30.0)
        else:
            response = await client.post(url, headers=headers, timeout=30.0)
    except Exception as exc:  # noqa: BLE001
        return CallResult(
            label=label,
            latency_ms=round((time.perf_counter() - t0) * 1000, 1),
            error=str(exc),
            expected_region=expected_region,
        )

    latency_ms = round((time.perf_counter() - t0) * 1000, 1)

    try:
        body = response.json()
    except Exception:  # noqa: BLE001
        body = response.text

    return CallResult(
        label=label,
        latency_ms=latency_ms,
        status_code=response.status_code,
        body=body,
        expected_region=expected_region,
    )


# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------

def print_result(r: CallResult) -> None:
    status_icon = "✓" if r.ok else "✗"

    region_tag = ""
    if r.region_matches is True:
        region_tag = "  [region ✓]"
    elif r.region_matches is False:
        actual = r.body.get("region") if isinstance(r.body, dict) else "?"
        region_tag = f"  [region ✗  expected={r.expected_region} got={actual}]"

    if r.error:
        print(f"  ✗ {r.label}: ERROR — {r.error}  ({r.latency_ms} ms)")
    else:
        print(f"  {status_icon} {r.label}: HTTP {r.status_code}{region_tag}  ({r.latency_ms} ms)")
        if isinstance(r.body, dict):
            print(f"      {json.dumps(r.body)}")


def print_section(title: str) -> None:
    width = 62
    print(f"\n{'=' * width}")
    print(f"  {title}")
    print(f"{'=' * width}")


# ---------------------------------------------------------------------------
# Test runner
# ---------------------------------------------------------------------------

async def run_tests(
    token: str,
    us_east_1_url: str,
    eu_west_1_url: str,
) -> bool:
    all_results: list[CallResult] = []

    async with httpx.AsyncClient() as client:

        # --- Phase 1: concurrent /greet ---
        print_section("PHASE 1 — Concurrent GET /greet (both regions)")
        greet_results = await asyncio.gather(
            call_endpoint(
                client,
                f"{us_east_1_url.rstrip('/')}/greet",
                token, "GET",
                label="us-east-1  /greet",
                expected_region="us-east-1",
            ),
            call_endpoint(
                client,
                f"{eu_west_1_url.rstrip('/')}/greet",
                token, "GET",
                label="eu-west-1  /greet",
                expected_region="eu-west-1",
            ),
        )
        for r in greet_results:
            print_result(r)
        all_results.extend(greet_results)

        # --- Phase 2: concurrent /dispatch ---
        print_section("PHASE 2 — Concurrent POST /dispatch (both regions)")
        dispatch_results = await asyncio.gather(
            call_endpoint(
                client,
                f"{us_east_1_url.rstrip('/')}/dispatch",
                token, "POST",
                label="us-east-1  /dispatch",
                expected_region="us-east-1",
            ),
            call_endpoint(
                client,
                f"{eu_west_1_url.rstrip('/')}/dispatch",
                token, "POST",
                label="eu-west-1  /dispatch",
                expected_region="eu-west-1",
            ),
        )
        for r in dispatch_results:
            print_result(r)
        all_results.extend(dispatch_results)

    # --- Summary ---
    print_section("SUMMARY")

    passed = sum(1 for r in all_results if r.ok and r.region_matches is not False)
    total = len(all_results)
    print(f"\n  Result: {passed}/{total} assertions passed\n")

    print("  Latency breakdown:")
    for r in all_results:
        mark = "✓" if r.ok else "✗"
        print(f"    {mark}  {r.label:<28} {r.latency_ms:>8.1f} ms")

    # Geographic latency delta for /greet
    us_greet = next((r for r in greet_results if "us-east" in r.label), None)
    eu_greet = next((r for r in greet_results if "eu-west" in r.label), None)
    if us_greet and eu_greet and us_greet.latency_ms and eu_greet.latency_ms:
        delta = abs(eu_greet.latency_ms - us_greet.latency_ms)
        faster = "us-east-1" if us_greet.latency_ms < eu_greet.latency_ms else "eu-west-1"
        print(f"\n  Geographic /greet latency delta: {delta:.1f} ms  ({faster} was faster)")

    return passed == total


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Unleash Live multi-region deployment validation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--user-pool-id", required=True, help="Cognito User Pool ID")
    parser.add_argument("--client-id", required=True, help="Cognito App Client ID")
    parser.add_argument("--username", required=True, help="Test user email")
    parser.add_argument("--password", required=True, help="Test user password")
    parser.add_argument("--us-east-1-url", required=True, dest="us_east_1_url",
                        help="API Gateway base URL for us-east-1")
    parser.add_argument("--eu-west-1-url", required=True, dest="eu_west_1_url",
                        help="API Gateway base URL for eu-west-1")
    args = parser.parse_args()

    token = authenticate(
        user_pool_id=args.user_pool_id,
        client_id=args.client_id,
        username=args.username,
        password=args.password,
    )

    success = asyncio.run(
        run_tests(
            token=token,
            us_east_1_url=args.us_east_1_url,
            eu_west_1_url=args.eu_west_1_url,
        )
    )

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
