# unleash-assessment

Multi-region AWS compute stack with Cognito auth, API Gateway, Lambda, DynamoDB, and ECS Fargate — provisioned with Terraform.

---

## Structure

```
├── modules/
│   ├── aws-terraform-labels/       # shared naming & tags
│   ├── aws-terraform-cognito/      # user pool, client, test user
│   ├── aws-terraform-networking/   # VPC, public subnets, IGW, SG
│   ├── aws-terraform-dynamodb/     # GreetingLogs table
│   ├── aws-terraform-lambda/       # generic Lambda + IAM wrapper
│   ├── aws-terraform-api-gateway/  # HTTP API v2 + JWT authorizer
│   └── aws-terraform-ecs/          # cluster, task definition, roles
├── stacks/
│   ├── auth/                       # Cognito (us-east-1 only)
│   └── regional/                   # identical stack deployed to each region
├── environments/
│   ├── us-east-1.tfvars
│   └── eu-west-1.tfvars
├── lambda/
│   ├── greeter/handler.py
│   └── dispatcher/handler.py
├── tests/test_deployment.py
└── .github/workflows/deploy.yml
```

---

## Deploy

**Requirements:** Terraform ≥ 1.5, AWS CLI configured.

### Step 1 — Auth stack (once, us-east-1)

```bash
cd stacks/auth
export TF_VAR_user_temp_password="Anmol@123"
terraform init
terraform apply
```

Note the outputs: `user_pool_id`, `user_pool_arn`, `client_id`.

### Step 2 — Regional stacks

Cognito outputs are read automatically from the auth stack's state file — no manual variable passing needed.

```bash
cd stacks/regional

# us-east-1
terraform workspace new us-east-1
terraform init
terraform apply -var-file="../../environments/us-east-1.tfvars"

# eu-west-1
terraform workspace new eu-west-1
terraform apply -var-file="../../environments/eu-west-1.tfvars"
```

---

## Test

```bash
pip install -r tests/requirements.txt

python3 tests/test_deployment.py \
  --user-pool-id  us-east-1_2YtEPIfev \
  --client-id     1hla7df6i4e4hk3abhqeul1r06 \
  --username      anmoldongol4444@gmail.com \
  --password      Anmol@123 \
  --us-east-1-url https://py47t25uoh.execute-api.us-east-1.amazonaws.com \
  --eu-west-1-url https://xnwolpukj1.execute-api.eu-west-1.amazonaws.com 
```

The script authenticates with Cognito, concurrently calls `/greet` and `/dispatch` in both regions, asserts each response contains the correct region, and prints latency for each call.

---

## CI/CD

`.github/workflows/deploy.yml` pipeline stages:

| Stage | Runs on |
|-------|---------|
| Lint + `terraform validate` | PR & push |
| Security scan (tfsec + Checkov) | PR & push |
| `terraform plan` (auth + both regions) | PR & push |
| `terraform apply` auth → regions | push to `main` |
| Integration test placeholder | push to `main` |

### Secrets required in GitHub

| Secret | Value |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | IAM credentials |
| `AWS_SECRET_ACCESS_KEY` | IAM credentials |
| `COGNITO_USER_EMAIL` | `anmoldongol4444@gmail.com` |
| `COGNITO_TEMP_PASSWORD` | Temporary password (auth stack apply) |
| `COGNITO_USER_PASSWORD` | Permanent password (test script) |

> Cognito pool ID and client ID are resolved automatically via `terraform_remote_state` — no longer needed as secrets.
