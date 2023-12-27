set dotenv-load

help:
  @just --list

# List the s3 buckets
list-s3:
    aws s3 ls --endpoint-url=http://localhost:4566

# List the dynamo tables
list-dynamo:
    aws dynamodb list-tables --endpoint-url=http://localhost:4566

# List the SQS tables
list-sqs:
    aws sqs list-queues --endpoint-url=http://localhost:4566

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

# Run the tests
test:
    terraform -chdir=./modules/s3 init
    terraform -chdir=./modules/s3 test
    terraform init
    terraform test
