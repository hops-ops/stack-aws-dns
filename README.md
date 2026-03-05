# stack-aws-dns

Deploys DNS and TLS automation: Route53 hosted zones, ExternalDNS for automatic DNS record management, CertManager for automated TLS certificates, and a ClusterIssuer configured for Let's Encrypt DNS-01 validation via Route53.

## Why DNSStack?

**Without DNSStack:**
- Manual DNS record management for every service endpoint
- Manual TLS certificate provisioning and renewal
- Separate IAM roles, policies, and Helm releases to coordinate
- Easy to misconfigure DNS-01 solvers or forget to wire hosted zone IDs

**With DNSStack:**
- Single claim provisions Route53 zones, ExternalDNS, CertManager, and ClusterIssuer
- Automatic DNS record creation for Kubernetes Services and Ingresses
- Automatic TLS certificate issuance and renewal via Let's Encrypt
- Hosted zone IDs automatically wired into ClusterIssuer DNS-01 solvers

## The Journey

### Stage 1: Getting Started

Minimal configuration for a single domain with automatic DNS and TLS.

```yaml
apiVersion: stacks.aws.hops.ops.com.ai/v1alpha1
kind: DNSStack
metadata:
  name: dns
  namespace: default
spec:
  clusterName: my-cluster
  aws:
    region: us-east-1
  domains:
  - name: example.com
  clusterIssuer:
    email: admin@example.com
```

This creates:
- A Route53 hosted zone for `example.com`
- ExternalDNS watching for DNS annotations on Services/Ingresses
- CertManager with a ClusterIssuer using Let's Encrypt production

### Stage 2: Growing (Multiple Domains)

Add multiple domains and customize AWS settings.

```yaml
apiVersion: stacks.aws.hops.ops.com.ai/v1alpha1
kind: DNSStack
metadata:
  name: dns
  namespace: default
spec:
  clusterName: prod-cluster
  aws:
    region: us-west-2
    permissionsBoundaryArn: arn:aws:iam::123456789012:policy/boundary
    rolePrefix: prod-
    tags:
      environment: production
  domains:
  - name: example.com
  - name: internal.example.com
  clusterIssuer:
    email: platform@example.com
```

### Stage 3: Import Existing

Adopt existing Route53 hosted zones without recreating them.

```yaml
apiVersion: stacks.aws.hops.ops.com.ai/v1alpha1
kind: DNSStack
metadata:
  name: dns
  namespace: default
spec:
  clusterName: prod-cluster
  aws:
    region: us-west-2
  domains:
  - name: example.com
    externalName: Z1234567890ABC
  clusterIssuer:
    email: platform@example.com
```

## Status

```yaml
status:
  ready: true
  hostedZones:
  - domain: example.com
    zoneId: "Z1234567890ABC"
```

| Field | Description |
|-------|-------------|
| `ready` | Whether all components are ready |
| `hostedZones[].domain` | Domain name |
| `hostedZones[].zoneId` | Route53 hosted zone ID |

## Composed Resources

- `Route53 Zone` - One per domain in `spec.domains`
- `ExternalDNS` (sub-XRD) - Helm chart + PodIdentity for automatic DNS record management
- `CertManager` (sub-XRD) - Helm chart + PodIdentity for TLS certificate automation
- `Kubernetes Object (ClusterIssuer)` - Let's Encrypt ACME issuer with DNS-01 Route53 solver

## Configuration Reference

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `clusterName` | Yes | - | Target cluster name |
| `aws.region` | Yes | - | AWS region |
| `aws.permissionsBoundaryArn` | No | - | IAM permissions boundary |
| `aws.rolePrefix` | No | - | Prefix for IAM role names |
| `aws.tags` | No | `{}` | Additional AWS tags |
| `domains[].name` | Yes | - | Domain name |
| `domains[].externalName` | No | - | Existing zone ID to import |
| `externalDNS.enabled` | No | `true` | Deploy ExternalDNS |
| `certManager.enabled` | No | `true` | Deploy CertManager |
| `clusterIssuer.enabled` | No | `true` | Create ClusterIssuer |
| `clusterIssuer.email` | No | - | Let's Encrypt registration email |
| `clusterIssuer.staging` | No | `false` | Use staging ACME server |

## Development

```bash
make render          # Render all examples
make validate        # Validate all examples
make test            # Run unit tests
make e2e             # Run E2E tests
```

## License

Apache-2.0
