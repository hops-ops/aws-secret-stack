# aws-secret-stack

Installs external-secrets with AWS Pod Identity for Secrets Manager and SSM Parameter Store access. Optionally creates a SecretStore and SOPS KMS key.

## Overview

Composes a `helm.m.crossplane.io/Release` for external-secrets with `aws.hops.ops.com.ai/PodIdentity`.
Automatically provisions IAM role and Pod Identity association for external-secrets' service account.

Additionally:
- Creates a **SecretStore** (namespaced by default) or **ClusterSecretStore** (opt-in) pointing to AWS Secrets Manager, so ExternalSecrets can pull secrets immediately
- Optionally creates a **SOPS KMS key** for encrypting secrets in git via the hops CLI (enabled by default)

## Usage

Minimal — installs ESO, PodIdentity, ClusterSecretStore, and SOPS KMS key:

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

With custom values and role prefix:

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
    tags:
      environment: production
```

ClusterSecretStore (cluster-wide access):

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: SecretStack
metadata:
  name: external-secrets
  namespace: default
spec:
  clusterName: my-cluster
  secretStore:
    scope: Cluster
  aws:
    region: us-east-1
```

ESO only — no SecretStore, no SOPS KMS key:

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: SecretStack
metadata:
  name: external-secrets
  namespace: default
spec:
  clusterName: my-cluster
  secretStore:
    enabled: false
  sops:
    enabled: false
  aws:
    region: us-east-1
```

## What Gets Created

| Resource | Condition | Description |
|----------|-----------|-------------|
| `helm.m.crossplane.io/Release` | Always | external-secrets Helm release (chart v2.2.0) |
| `aws.hops.ops.com.ai/PodIdentity` | Always | IAM role + Pod Identity with Secrets Manager, SSM, and KMS permissions |
| `kubernetes.m.crossplane.io/Object` (SecretStore) | `secretStore.enabled` (default true) | ClusterSecretStore or SecretStore wired to AWS Secrets Manager via PodIdentity JWT auth |
| `kms.aws.m.upbound.io/Key` | `sops.enabled` (default true) | KMS key with rotation for SOPS encryption. ARN exposed in `status.kmsKeyArn` |

## SecretStore Options

| Field | Default | Description |
|-------|---------|-------------|
| `secretStore.enabled` | `true` | Create a SecretStore resource |
| `secretStore.scope` | `Namespaced` | `Namespaced` for SecretStore, `Cluster` for ClusterSecretStore |
| `secretStore.name` | `default` | Name of the SecretStore resource |

## Status

| Field | Description |
|-------|-------------|
| `ready` | Overall stack readiness |
| `kmsKeyArn` | ARN of the SOPS KMS key (empty when sops disabled) |

The `kmsKeyArn` is used by the hops CLI to write `.sops.yaml` for git-based secret encryption.

## Development

```bash
make render      # render all examples
make validate    # validate rendered output
make test        # run KCL unit tests
make e2e         # run E2E tests (requires AWS credentials)
```
