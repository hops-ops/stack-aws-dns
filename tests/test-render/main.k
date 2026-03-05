import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# ==============================================================================
# Unit tests for stacks.aws DNSStack XRD
# ==============================================================================

_items = [
    # ==========================================================================
    # Test 1: Minimal input renders ExternalDNS, CertManager, and ClusterIssuer
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "minimal-renders-all-components"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "stacks.aws.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    aws = {
                        region = "us-east-1"
                    }
                    clusterIssuer = {
                        email = "admin@example.com"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.aws.hops.ops.com.ai/v1alpha1"
                    kind = "ExternalDNS"
                    metadata.name = "dns-edns"
                    spec = {
                        clusterName = "my-cluster"
                        aws.region = "us-east-1"
                    }
                }
                {
                    apiVersion = "helm.aws.hops.ops.com.ai/v1alpha1"
                    kind = "CertManager"
                    metadata.name = "dns-cm"
                    spec = {
                        clusterName = "my-cluster"
                        aws.region = "us-east-1"
                    }
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha2"
                    kind = "Object"
                    metadata.name = "dns-cluster-issuer"
                    spec = {
                        forProvider = {
                            manifest = {
                                apiVersion = "cert-manager.io/v1"
                                kind = "ClusterIssuer"
                                metadata.name = "letsencrypt-prod"
                                spec.acme = {
                                    email = "admin@example.com"
                                    server = "https://acme-v02.api.letsencrypt.org/directory"
                                    privateKeySecretRef.name = "letsencrypt-prod-account-key"
                                    solvers = [{
                                        dns01.route53.region = "us-east-1"
                                    }]
                                }
                            }
                        }
                        providerConfigRef = {
                            name = "my-cluster"
                            kind = "ProviderConfig"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 2: Staging flag switches to LE staging server and name
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "staging-flag-switches-server"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "stacks.aws.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    aws = {
                        region = "us-east-1"
                    }
                    clusterIssuer = {
                        email = "admin@example.com"
                        staging = True
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha2"
                    kind = "Object"
                    metadata.name = "dns-cluster-issuer"
                    spec.forProvider.manifest = {
                        apiVersion = "cert-manager.io/v1"
                        kind = "ClusterIssuer"
                        metadata.name = "letsencrypt-staging"
                        spec.acme = {
                            server = "https://acme-staging-v02.api.letsencrypt.org/directory"
                            email = "admin@example.com"
                            privateKeySecretRef.name = "letsencrypt-staging-account-key"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 3: Provider config refs propagate correctly
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "provider-config-refs-propagate"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "stacks.aws.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    helmProviderConfigRef = {
                        name = "custom-helm"
                        kind = "ClusterProviderConfig"
                    }
                    kubernetesProviderConfigRef = {
                        name = "custom-k8s"
                    }
                    awsProviderConfigRef = {
                        name = "custom-aws"
                    }
                    aws = {
                        region = "eu-west-1"
                    }
                    clusterIssuer = {
                        email = "admin@example.com"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.aws.hops.ops.com.ai/v1alpha1"
                    kind = "ExternalDNS"
                    metadata.name = "dns-edns"
                    spec = {
                        helmProviderConfigRef = {
                            name = "custom-helm"
                            kind = "ClusterProviderConfig"
                        }
                        awsProviderConfigRef = {
                            name = "custom-aws"
                            kind = "ProviderConfig"
                        }
                    }
                }
                {
                    apiVersion = "kubernetes.m.crossplane.io/v1alpha2"
                    kind = "Object"
                    metadata.name = "dns-cluster-issuer"
                    spec.providerConfigRef = {
                        name = "custom-k8s"
                        kind = "ProviderConfig"
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 4: Disabling components omits them
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "disabled-components-omitted"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "stacks.aws.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    aws = {
                        region = "us-east-1"
                    }
                    externalDNS = {
                        enabled = False
                    }
                    certManager = {
                        enabled = False
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "stacks.aws.hops.ops.com.ai/v1alpha1"
                    kind = "DNSStack"
                    metadata.name = "dns"
                    status.ready = False
                }
            ]
        }
    }

    # ==========================================================================
    # Test 5: AWS config passes through to sub-XRDs
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "aws-config-passthrough"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "stacks.aws.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "prod-cluster"
                    aws = {
                        region = "us-west-2"
                        permissionsBoundaryArn = "arn:aws:iam::123456789012:policy/boundary"
                        rolePrefix = "prod-"
                    }
                    clusterIssuer = {
                        email = "admin@example.com"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.aws.hops.ops.com.ai/v1alpha1"
                    kind = "ExternalDNS"
                    metadata.name = "dns-edns"
                    spec.aws = {
                        region = "us-west-2"
                        permissionsBoundaryArn = "arn:aws:iam::123456789012:policy/boundary"
                        rolePrefix = "prod-"
                    }
                }
                {
                    apiVersion = "helm.aws.hops.ops.com.ai/v1alpha1"
                    kind = "CertManager"
                    metadata.name = "dns-cm"
                    spec.aws = {
                        region = "us-west-2"
                        permissionsBoundaryArn = "arn:aws:iam::123456789012:policy/boundary"
                        rolePrefix = "prod-"
                    }
                }
            ]
        }
    }
    # ==========================================================================
    # Test 6: Domains create Route53 Zone resources
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "domains-create-hosted-zones"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "stacks.aws.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    aws = {
                        region = "us-east-1"
                    }
                    domains = [
                        {name = "example.com"}
                        {name = "internal.example.com"}
                    ]
                    clusterIssuer = {
                        email = "admin@example.com"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "route53.aws.m.upbound.io/v1beta1"
                    kind = "Zone"
                    metadata.name = "dns-hz-example-com"
                    spec = {
                        forProvider.name = "example.com"
                        providerConfigRef.name = "default"
                    }
                }
                {
                    apiVersion = "route53.aws.m.upbound.io/v1beta1"
                    kind = "Zone"
                    metadata.name = "dns-hz-internal-example-com"
                    spec = {
                        forProvider.name = "internal.example.com"
                        providerConfigRef.name = "default"
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 7: domainFilters auto-wired into ExternalDNS values
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "domain-filters-auto-wired"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "stacks.aws.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    aws = {
                        region = "us-east-1"
                    }
                    domains = [
                        {name = "example.com"}
                    ]
                    clusterIssuer = {
                        email = "admin@example.com"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.aws.hops.ops.com.ai/v1alpha1"
                    kind = "ExternalDNS"
                    metadata.name = "dns-edns"
                    spec.values.domainFilters = ["example.com"]
                }
            ]
        }
    }

    # ==========================================================================
    # Test 8: externalName annotation set when provided
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "external-name-annotation-set"
        spec = {
            compositionPath = "apis/dnsstacks/composition.yaml"
            xrdPath = "apis/dnsstacks/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = {
                apiVersion = "stacks.aws.hops.ops.com.ai/v1alpha1"
                kind = "DNSStack"
                metadata.name = "dns"
                spec = {
                    clusterName = "my-cluster"
                    aws = {
                        region = "us-east-1"
                    }
                    domains = [
                        {name = "example.com", externalName = "Z1234567890ABC"}
                    ]
                    clusterIssuer = {
                        email = "admin@example.com"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "route53.aws.m.upbound.io/v1beta1"
                    kind = "Zone"
                    metadata = {
                        name = "dns-hz-example-com"
                        annotations = {
                            "crossplane.io/external-name" = "Z1234567890ABC"
                        }
                    }
                }
            ]
        }
    }
]

items = _items
