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
]

items = _items
