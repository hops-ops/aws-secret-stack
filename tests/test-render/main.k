import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# ==============================================================================
# Unit tests for aws SecretStack XRD
# ==============================================================================

_items = [
    # ==========================================================================
    # Test 1: Minimal input renders Helm ExternalSecrets and Pod Identity
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "minimal-renders-helm-and-pod-identity"
        spec = {
            compositionPath = "apis/secretstacks/composition.yaml"
            xrdPath = "apis/secretstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "SecretStack"
                metadata.name = "external-secrets"
                spec = {
                    clusterName = "my-cluster"
                    aws = {
                        region = "us-east-1"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.hops.ops.com.ai/v1alpha1"
                    kind = "ExternalSecrets"
                    metadata.name = "external-secrets"
                    spec.clusterName = "my-cluster"
                }
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "PodIdentity"
                    metadata.name = "external-secrets-pod-identity"
                    spec = {
                        clusterName = "my-cluster"
                        region = "us-east-1"
                        serviceAccount = {
                            name = "external-secrets"
                            namespace = "external-secrets"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 2: Custom namespace propagates to both resources
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-namespace-propagates"
        spec = {
            compositionPath = "apis/secretstacks/composition.yaml"
            xrdPath = "apis/secretstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "SecretStack"
                metadata.name = "external-secrets"
                spec = {
                    clusterName = "prod-cluster"
                    namespace = "secrets-system"
                    aws = {
                        region = "us-west-2"
                        rolePrefix = "prod-"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.hops.ops.com.ai/v1alpha1"
                    kind = "ExternalSecrets"
                    metadata.name = "external-secrets"
                    spec.namespace = "secrets-system"
                }
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "PodIdentity"
                    metadata.name = "external-secrets-pod-identity"
                    spec = {
                        rolePrefix = "prod-"
                        serviceAccount = {
                            namespace = "secrets-system"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 3: SOPS KMS key rendered by default
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "sops-kms-key-rendered-by-default"
        spec = {
            compositionPath = "apis/secretstacks/composition.yaml"
            xrdPath = "apis/secretstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "SecretStack"
                metadata.name = "external-secrets"
                spec = {
                    clusterName = "my-cluster"
                    aws.region = "us-east-1"
                }
            }
            assertResources = [
                {
                    apiVersion = "kms.aws.m.upbound.io/v1beta1"
                    kind = "Key"
                    metadata.name = "external-secrets-sops"
                    spec.forProvider = {
                        region = "us-east-1"
                        enableKeyRotation = True
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 4: SOPS KMS key disabled when sops.enabled is false
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "sops-disabled-no-kms-key"
        spec = {
            compositionPath = "apis/secretstacks/composition.yaml"
            xrdPath = "apis/secretstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "SecretStack"
                metadata.name = "no-sops"
                spec = {
                    clusterName = "my-cluster"
                    sops.enabled = False
                    aws.region = "us-east-1"
                }
            }
            # Only Helm + PodIdentity should render, no KMS Key
            assertResources = [
                {
                    apiVersion = "helm.hops.ops.com.ai/v1alpha1"
                    kind = "ExternalSecrets"
                    metadata.name = "no-sops"
                }
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "PodIdentity"
                    metadata.name = "no-sops-pod-identity"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 5: Namespaced SecretStore renders by default when ESO is ready
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "secret-store-default-namespaced"
        spec = {
            compositionPath = "apis/secretstacks/composition.yaml"
            xrdPath = "apis/secretstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "SecretStack"
                metadata.name = "external-secrets"
                spec = {
                    clusterName = "my-cluster"
                    aws.region = "us-east-1"
                }
            }
            observedResources = [
                {
                    apiVersion = "helm.hops.ops.com.ai/v1alpha1"
                    kind = "ExternalSecrets"
                    metadata = {
                        name = "external-secrets"
                        annotations = {"crossplane.io/composition-resource-name" = "helm-external-secrets"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
            ]
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "external-secrets-secret-store"
                    spec.forProvider.manifest = {
                        apiVersion = "external-secrets.io/v1"
                        kind = "SecretStore"
                        metadata = {
                            name = "default"
                            namespace = "external-secrets"
                        }
                        spec.provider.aws = {
                            service = "SecretsManager"
                            region = "us-east-1"
                            auth.jwt.serviceAccountRef.name = "external-secrets"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 6: KMS ARN exposed in status when key is ready
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "kms-arn-in-status"
        spec = {
            compositionPath = "apis/secretstacks/composition.yaml"
            xrdPath = "apis/secretstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "SecretStack"
                metadata.name = "external-secrets"
                spec = {
                    clusterName = "my-cluster"
                    aws.region = "us-east-1"
                }
            }
            observedResources = [
                {
                    apiVersion = "kms.aws.m.upbound.io/v1beta1"
                    kind = "Key"
                    metadata = {
                        name = "external-secrets-sops"
                        annotations = {"crossplane.io/composition-resource-name" = "kms-key"}
                    }
                    status = {
                        conditions = [
                            {type = "Ready", status = "True"}
                            {type = "Synced", status = "True"}
                        ]
                        atProvider.arn = "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
                    }
                }
            ]
            assertResources = [
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "SecretStack"
                    metadata.name = "external-secrets"
                    status.kmsKeyArn = "arn:aws:kms:us-east-1:123456789012:key/test-key-id"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 7: KMS key uses AWS tags with Name tag
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "kms-key-tags-include-name"
        spec = {
            compositionPath = "apis/secretstacks/composition.yaml"
            xrdPath = "apis/secretstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "SecretStack"
                metadata.name = "my-stack"
                spec = {
                    clusterName = "prod"
                    aws = {
                        region = "us-west-2"
                        tags = {
                            environment = "production"
                        }
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "kms.aws.m.upbound.io/v1beta1"
                    kind = "Key"
                    metadata.name = "my-stack-sops"
                    spec.forProvider.tags = {
                        Name = "my-stack-sops"
                        environment = "production"
                        "hops.ops.com.ai/managed" = "true"
                        "hops.ops.com.ai/secretstack" = "my-stack"
                    }
                }
            ]
        }
    }
    # ==========================================================================
    # Test 8: ClusterSecretStore when scope is Cluster (opt-in)
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "cluster-secret-store-opt-in"
        spec = {
            compositionPath = "apis/secretstacks/composition.yaml"
            xrdPath = "apis/secretstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "SecretStack"
                metadata.name = "external-secrets"
                spec = {
                    clusterName = "my-cluster"
                    secretStore.scope = "Cluster"
                    aws.region = "us-east-1"
                }
            }
            observedResources = [
                {
                    apiVersion = "helm.hops.ops.com.ai/v1alpha1"
                    kind = "ExternalSecrets"
                    metadata = {
                        name = "external-secrets"
                        annotations = {"crossplane.io/composition-resource-name" = "helm-external-secrets"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
            ]
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "external-secrets-cluster-secret-store"
                    spec.forProvider.manifest = {
                        apiVersion = "external-secrets.io/v1"
                        kind = "ClusterSecretStore"
                        metadata.name = "default"
                        spec.provider.aws = {
                            service = "SecretsManager"
                            region = "us-east-1"
                            auth.jwt.serviceAccountRef = {
                                name = "external-secrets"
                                namespace = "external-secrets"
                            }
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 9: SecretStore disabled renders nothing
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "secret-store-disabled"
        spec = {
            compositionPath = "apis/secretstacks/composition.yaml"
            xrdPath = "apis/secretstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "SecretStack"
                metadata.name = "no-store"
                spec = {
                    clusterName = "my-cluster"
                    secretStore.enabled = False
                    sops.enabled = False
                    aws.region = "us-east-1"
                }
            }
            observedResources = [
                {
                    apiVersion = "helm.hops.ops.com.ai/v1alpha1"
                    kind = "ExternalSecrets"
                    metadata = {
                        name = "no-store"
                        annotations = {"crossplane.io/composition-resource-name" = "helm-external-secrets"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
            ]
            # Only Helm + PodIdentity + Usage, no SecretStore, no KMS Key
            assertResources = [
                {
                    apiVersion = "helm.hops.ops.com.ai/v1alpha1"
                    kind = "ExternalSecrets"
                    metadata.name = "no-store"
                }
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "PodIdentity"
                    metadata.name = "no-store-pod-identity"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 10: Custom SecretStore name
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-secret-store-name"
        spec = {
            compositionPath = "apis/secretstacks/composition.yaml"
            xrdPath = "apis/secretstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                kind = "SecretStack"
                metadata.name = "external-secrets"
                spec = {
                    clusterName = "my-cluster"
                    secretStore.name = "aws-sm"
                    aws.region = "us-east-1"
                }
            }
            observedResources = [
                {
                    apiVersion = "helm.hops.ops.com.ai/v1alpha1"
                    kind = "ExternalSecrets"
                    metadata = {
                        name = "external-secrets"
                        annotations = {"crossplane.io/composition-resource-name" = "helm-external-secrets"}
                    }
                    status.conditions = [
                        {type = "Ready", status = "True"}
                        {type = "Synced", status = "True"}
                    ]
                }
            ]
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha1"
                    kind = "Object"
                    metadata.name = "external-secrets-secret-store"
                    spec.forProvider.manifest.metadata.name = "aws-sm"
                }
            ]
        }
    }
]

items = _items
