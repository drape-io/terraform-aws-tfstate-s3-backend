# Releasing a new version

Tag the release and push the tag:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

# Development
The tests run against [LocalStack](https://www.localstack.cloud/). The
`docker-compose.yml` file starts it.

1. Load the AWS settings from `.envrc`:

```bash
source .envrc
```

2. Start LocalStack:

```bash
just localstack-up
```

## Testing
Validate the root module, the s3 module and the full example:

```bash
just validate
```

Run the tests for the s3 module, the replication module and the root module:

```bash
just test
```

## Integration Testing

To list the tables and buckets in LocalStack:

```bash
just list-dynamo
just list-s3
```

To delete a lock table by hand:

```bash
aws dynamodb delete-table --endpoint-url=http://localhost:4566 --table-name drape-customer1-dev-k8s-tfstate
```
