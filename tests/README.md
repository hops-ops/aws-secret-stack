# Tests

## Unit Tests (test-render)

Validates composition logic without deploying resources.

```bash
make render   # Run composition render tests
make test     # Run all unit tests
```

## E2E Tests (e2etest-secretstacks)

Full integration test that deploys real AWS infrastructure:
1. Creates AutoEKSCluster using persistent hops-test network
2. Deploys aws SecretStack (external-secrets + AWS Pod Identity)

### Prerequisites

1. Create `tests/e2etest-secretstacks/secrets/aws-creds` with AWS credentials:
   ```ini
   [default]
   aws_access_key_id = AKIA...
   aws_secret_access_key = ...
   ```

2. Ensure the persistent hops-test network exists (from aws-network e2e test)

### Running E2E Tests

```bash
make e2e      # Run full e2e test (~90 min for EKS creation)
```

**Note**: E2E tests create real AWS resources and can take up to 90 minutes to complete.
