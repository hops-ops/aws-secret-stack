import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# ==============================================================================
# Unit tests for aws SecretStack XRD
# ==============================================================================

_items = [
    # ==========================================================================
    # Test 1: Minimal input renders Helm Release and Pod Identity
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
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "external-secrets"
                    spec.forProvider.chart.name = "external-secrets"
                }
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "PodIdentity"
                    metadata.name = "external-secrets"
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
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "external-secrets"
                    spec.forProvider.namespace = "secrets-system"
                }
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "PodIdentity"
                    metadata.name = "external-secrets"
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
    # Test 3: Namespaced SecretStore renders by default when ESO is ready
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
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
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
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 4: ClusterSecretStore when scope is Cluster (opt-in)
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
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
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
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 5: SecretStore disabled renders nothing
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
                    aws.region = "us-east-1"
                }
            }
            observedResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
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
            # Only Helm + PodIdentity + Usage, no SecretStore
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "no-store"
                }
                {
                    apiVersion = "aws.hops.ops.com.ai/v1alpha1"
                    kind = "PodIdentity"
                    metadata.name = "no-store"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 6: Custom SecretStore name
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
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
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
