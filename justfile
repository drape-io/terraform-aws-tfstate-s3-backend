set dotenv-load

help:
  @just --list

# Generate README with terraform-docs
readme:
    terraform-docs markdown table --output-file README.md --output-mode inject .

# Format all terraform files
fmt:
    terraform fmt -recursive

# Format check (CI mode, no writes)
fmt-check:
    terraform fmt -check -recursive

# Validate the root module, the s3 module, and (through the full example) the replication module
validate:
    terraform init -backend=false
    terraform validate
    terraform -chdir=modules/s3 init -backend=false
    terraform -chdir=modules/s3 validate
    terraform -chdir=examples/full init -backend=false
    terraform -chdir=examples/full validate

# Run the tests (requires LocalStack running)
test:
    terraform -chdir=./modules/s3 init
    terraform -chdir=./modules/s3 test
    terraform -chdir=./modules/replication init
    terraform -chdir=./modules/replication test
    terraform init
    terraform test

# Start LocalStack
localstack-up:
    docker compose up -d

# Stop LocalStack
localstack-down:
    docker compose down

# List the s3 buckets
list-s3:
    aws s3 ls --endpoint-url=http://localhost:4566

# List the dynamo tables
list-dynamo:
    aws dynamodb list-tables --endpoint-url=http://localhost:4566

# Apply the full example to generate two backends
apply-example:
    terraform -chdir=./examples/full init
    terraform -chdir=./examples/full apply

# Destroy the example remote backends
destroy-example:
    terraform -chdir=./examples/full destroy

# Apply example that uses the remote backend
apply-remote:
    terraform -chdir=./examples/remote init
    terraform -chdir=./examples/remote apply

# Destroy the example that uses the remote backend
destroy-remote:
    terraform -chdir=./examples/remote init
    terraform -chdir=./examples/remote destroy
