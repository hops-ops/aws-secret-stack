# aws-secret-stack

Installs external-secrets with AWS Pod Identity for Secrets Manager and SSM Parameter Store access.

## Overview

Composes the base `helm.hops.ops.com.ai/ExternalSecrets` XRD with `aws.hops.ops.com.ai/PodIdentity`.
Automatically provisions IAM role and Pod Identity association for external-secrets' service account.

## Usage

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: SecretStack
metadata:
  name: external-secrets
  namespace: default
spec:
  clusterName: my-cluster
  aws:
    region: us-east-1
```

With custom values:

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: SecretStack
metadata:
  name: external-secrets
  namespace: default
spec:
  clusterName: production-cluster
  namespace: external-secrets
  values:
    serviceAccount:
      create: true
  aws:
    region: us-west-2
    rolePrefix: prod-
```

## What Gets Created

1. `helm.hops.ops.com.ai/ExternalSecrets` - the base external-secrets Helm release
2. `aws.hops.ops.com.ai/PodIdentity` - IAM role + Pod Identity association with Secrets Manager and SSM permissions

## Development

```bash
make render
make validate
make test
```
