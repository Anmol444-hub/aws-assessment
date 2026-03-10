# unleash-assessment

Multi-region AWS compute stack provisioned with Terraform. Centralised Cognito authentication in `us-east-1`, identical compute deployed independently to `us-east-1` and `eu-west-1`.

---

## Architecture

```
                        Cognito User Pool (us-east-1)
                               │  JWT validation
              ┌────────────────┴────────────────┐
              ▼                                 ▼
   API Gateway (us-east-1)          API Gateway (eu-west-1)
   ├─ GET  /greet                   ├─ GET  /greet
   └─ POST /dispatch                └─ POST /dispatch
        │          │                     │          │
        ▼          ▼                     ▼          ▼
    Lambda      Lambda               Lambda      Lambda
    Greeter   Dispatcher             Greeter   Dispatcher
        │          │                     │          │
        ▼          ▼                     ▼          ▼
    DynamoDB   ECS Fargate           DynamoDB   ECS Fargate
  GreetingLogs  (aws-cli)          GreetingLogs  (aws-cli)
                   │                                │
                   └──────────┬─────────────────────┘
                              ▼
                    SNS Topic (us-east-1)
               Candidate-Verification-Topic
```

- **Greeter Lambda** — writes to regional DynamoDB, publishes to SNS
- **Dispatcher Lambda** — triggers a one-shot ECS Fargate task via `RunTask`
- **ECS task** — runs `amazon/aws-cli`, publishes to SNS, exits
- **No NAT Gateway** — Fargate runs in public subnet with `assignPublicIp: ENABLED`
- **Cross-region SNS** — handled at application layer (`boto3` / `--region us-east-1` flag), not via provider aliases

---

## Structure

```
├── modules/
│   ├── aws-terraform-labels/       # shared naming & tags (name-env-region prefix)
│   ├── aws-terraform-cognito/      # user pool, app client, test user
│   ├── aws-terraform-networking/   # VPC, public subnets, IGW, route tables, SG
│   ├── aws-terraform-dynamodb/     # configurable DynamoDB table
│   ├── aws-terraform-lambda/       # generic Lambda + IAM + CloudWatch
│   ├── aws-terraform-api-gateway/  # HTTP API v2, JWT authorizer, dynamic routes
│   └── aws-terraform-ecs/          # cluster, task definition, execution/task roles
├── stacks/
│   ├── bootstrap/                  # S3 state bucket + DynamoDB lock table (run once)
│   ├── auth/                       # Cognito — us-east-1 only
│   └── regional/                   # compute stack — applied per region via tfvars
├── environments/
│   ├── backend-auth.hcl            # S3 backend config for auth stack
│   ├── backend-us-east-1.hcl       # S3 backend config for us-east-1
│   ├── backend-eu-west-1.hcl       # S3 backend config for eu-west-1
│   ├── us-east-1.tfvars            # region-specific input vars
│   └── eu-west-1.tfvars
├── lambda/
│   ├── greeter/handler.py
│   └── dispatcher/handler.py
├── tests/test_deployment.py
└── .github/workflows/deploy.yml
```

---

## Multi-Region Provider Design

Each stack has a **single provider** configured by `var.region`. The same `stacks/regional` code is applied twice using different `-backend-config` and `-var-file` flags — each deployment gets its own isolated S3 state key.

```
regional/us-east-1/terraform.tfstate   ← us-east-1 apply
regional/eu-west-1/terraform.tfstate   ← eu-west-1 apply
```

The regional stack reads Cognito outputs directly from the auth stack's S3 state via `terraform_remote_state` — no manual variable passing required.

---

## Deploy

**Requirements:** Terraform ≥ 1.5, AWS CLI configured with appropriate IAM permissions.

### Step 0 — Bootstrap (once ever)

```bash
cd stacks/bootstrap
terraform init
terraform apply
```

### Step 1 — Auth stack (once, us-east-1)

```bash
cd stacks/auth
export TF_VAR_user_temp_password="Anmol@123"
terraform init -backend-config="../../environments/backend-auth.hcl"
terraform apply
```

### Step 2 — Regional stacks

```bash
cd stacks/regional

# us-east-1
terraform init -backend-config="../../environments/backend-us-east-1.hcl"
terraform apply -var-file="../../environments/us-east-1.tfvars"

# eu-west-1
terraform init -backend-config="../../environments/backend-eu-west-1.hcl" -reconfigure
terraform apply -var-file="../../environments/eu-west-1.tfvars"
```

---

## Test

```bash
pip install -r tests/requirements.txt

python3 tests/test_deployment.py \
  --user-pool-id  us-east-1_RZD8viw3u \
  --client-id     6opd3av8k39iq48cbbfefvhhdp \
  --username      anmoldongol4444@gmail.com \
  --password      Anmol@123 \
  --us-east-1-url https://pz9v7sgt4f.execute-api.us-east-1.amazonaws.com \
  --eu-west-1-url https://4r1n5nrzh3.execute-api.eu-west-1.amazonaws.com
```

The script authenticates with Cognito, concurrently hits `/greet` and `/dispatch` in both regions, asserts each response contains the correct region name, and prints per-request latency to show the geographic performance difference.

---

## CI/CD

`.github/workflows/deploy.yml` runs on every PR and push to `main`.

| Job | Trigger | Description |
|-----|---------|-------------|
| `lint-validate` | PR + push | `terraform fmt -check` + `terraform validate` |
| `security-scan` | PR + push | tfsec + Checkov static analysis |
| `plan-auth` | PR + push | Plan auth stack |
| `deploy-auth` | push → main | Apply auth stack |
| `deploy-regional-us` | push → main | Apply us-east-1 regional stack |
| `deploy-regional-eu` | push → main | Apply eu-west-1 regional stack |
| `integration-tests` | push → main | Run `test_deployment.py` against live endpoints |

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM credentials |
| `AWS_SECRET_ACCESS_KEY` | IAM credentials |
| `COGNITO_USER_EMAIL` | `anmoldongol4444@gmail.com` |
| `COGNITO_TEMP_PASSWORD` | Temporary password used during `terraform apply` |
| `COGNITO_USER_PASSWORD` | Permanent password used by the test script |
