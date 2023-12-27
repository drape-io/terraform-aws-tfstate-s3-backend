# Releasing a new version:

```
git tag -a v0.0.1 -m "Release v0.0.1"
git push origin v0.0.1
```

# Development
We've included a `docker-compose.yml` file that will spin up LocalStack(https://www.localstack.cloud/)
and allow you to target that.

First, activate the `.envrc` file so you have the right AWS settings:

```bash
source .envrc
```

Then run docker:

```bash
docker compose up
```

## Unit Testing
```bash
tf test
```

## Integration Testing

You can verify everything is working with:

```
aws dynamodb list-tables --endpoint-url=http://localhost:4566
aws s3 ls --endpoint-url=http://localhost:4566
```

To manually clear out a lock table:

```
aws dynamodb delete-table --endpoint-url=http://localhost:4566 --table-name drape-customer1-dev-k8s-tfstate
```