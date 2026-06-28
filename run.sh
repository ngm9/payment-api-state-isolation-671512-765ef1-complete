#!/usr/bin/env bash
set -euo pipefail

cd /root/task

echo "==> Starting local AWS-compatible emulator (LocalStack)..."
docker compose up -d

echo "==> Waiting for LocalStack on 127.0.0.1:4566 ..."
for i in $(seq 1 30); do
  if curl -sf "http://127.0.0.1:4566/_localstack/health" >/dev/null 2>&1; then
    echo "    LocalStack is ready."
    break
  fi
  sleep 2
  if [ "$i" -eq 30 ]; then
    echo "ERROR: LocalStack did not become ready in time." >&2
    docker compose logs --tail=30 localstack >&2 || true
    exit 1
  fi
done

# ── Seed pre-existing backend infrastructure ──────────────────────────────────
# The task scenario assumes these resources are already deployed. We create the
# S3 bucket first (needed for terraform init), then apply to seed the rest.
AWS_CMD="aws --endpoint-url=http://127.0.0.1:4566 --region us-east-1"
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

echo "==> Creating Terraform state bucket in LocalStack..."
$AWS_CMD s3 mb s3://payments-tf-state 2>/dev/null || true

echo "==> Running terraform init (connect to S3 backend)..."
terraform init -reconfigure -input=false 2>&1

echo "==> Seeding pre-existing infrastructure state (terraform apply)..."
# ECS is a LocalStack Pro feature and will fail silently here.
# IAM role, DynamoDB lock table, S3 bucket and versioning will be seeded.
set +e
terraform apply -auto-approve -input=false 2>&1 | grep -v "^$" || true
set -e

echo "==> Pre-existing resources now tracked in state:"
terraform state list 2>&1 || true

cat <<'EOF'

=========================================================
 Environment ready.
 LocalStack emulator: http://127.0.0.1:4566

 The project already has shared infrastructure deployed.
 Use the following to inspect and then fix the state:

   terraform fmt -check
   terraform state list        # inspect existing shared state
   terraform plan              # observe both environments in one plan
   terraform validate

 Your task: isolate state per environment and add locking.
=========================================================
EOF
