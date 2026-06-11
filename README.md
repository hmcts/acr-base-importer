# ACR Base Image Importer

Pipeline to automatically scan, import, and cache container images into the `hmctsprod` Azure Container Registry (ACR).

| Pipeline | Purpose |
|----------|---------|
| [`trivy-scan-import.yml`](trivy-scan-import.yml) | **Current** — Trivy security scanning + import + ACR cache rule management. Runs daily at 01:00 UTC. |
| [`base-image-import.yml`](base-image-import.yml) | **Legacy** — Direct import without Trivy scanning. Kept for reference. |

## Supported Upstream Image Repositories

Below is a table of upstream image repositories that will have supported cache rules in hmctsprod. No image tags are added by default, 
but will be added on the first running instance of `docker pull hmctsprod.azurecr.io/${destinationRepo}:image-tag`, where destinationRepo is the [mapped repository in our ACR for the upstream repository](acr-repositories.yaml), any upstream image tag is available.


| **Upstream Repository Name** | **HMCTS Repository Name** |
|-------------------------------|---------------------------|
| `atmoz/sftp` | `hmctsprod.azurecr.io/imported/atmoz/sftp` |
| `azure-storage/azurite` | `hmctsprod.azurecr.io/imported/azure-storage/azurite` |
| `bitnami/os-shell` | `hmctsprod.azurecr.io/imported/os-shell` |
| `citizensadvice/clamav-mock` | `hmctsprod.azurecr.io/imported/citizensadvice/clamav-mock` |
| `curlimages/curl` | `hmctsprod.azurecr.io/imported/curlimages/curl` |
| `datawire/tel2` | `hmctsprod.azurecr.io/imported/datawire/tel2` |
| `dius/pact-broker` | `hmctsprod.azurecr.io/imported/dius/pact-broker` |
| `drycc/service-catalog` | `hmctsprod.azurecr.io/imported/drycc/service-catalog` |
| `dynatrace/dynatrace-operator` | `hmctsprod.azurecr.io/imported/dynatrace/dynatrace-operator` |
| `elastic/elasticsearch` | `hmctsprod.azurecr.io/imported/elastic/elasticsearch` |
| `external-dns/external-dns` | `hmctsprod.azurecr.io/imported/k8s-sigs/external-dns` |
| `fluent/fluent-bit` | `hmctsprod.azurecr.io/imported/fluent/fluent-bit` |
| `grafana/grafana` | `hmctsprod.azurecr.io/imported/grafana` |
| `jbergknoff/postgresql-client` | `hmctsprod.azurecr.io/imported/jbergknoff/postgresql-client` |
| `jimmidyson/configmap-reload` | `hmctsprod.azurecr.io/imported/jimmidyson/configmap-reload` |
| `jqlang/jq` | `hmctsprod.azurecr.io/imported/jqlang/jq` |
| `kiwigrid/k8s-sidecar` | `hmctsprod.azurecr.io/imported/kiwigrid/k8s-sidecar` |
| `kubeshop/testkube-api-server` | `hmctsprod.azurecr.io/imported/kubeshop/testkube-api-server` |
| `kubeshop/testkube-dashboard` | `hmctsprod.azurecr.io/imported/kubeshop/testkube-dashboard` |
| `kubeshop/testkube-operator` | `hmctsprod.azurecr.io/imported/kubeshop/testkube-operator` |
| `library/alpine` | `hmctsprod.azurecr.io/imported/alpine` |
| `library/eclipse-temurin` | `hmctsprod.azurecr.io/imported/eclipse-temurin` |
| `library/logstash` | `hmctsprod.azurecr.io/imported/elastic/logstash` |
| `library/nats` | `hmctsprod.azurecr.io/imported/nats` |
| `library/nginx` | `hmctsprod.azurecr.io/imported/nginx` |
| `library/node` | `hmctsprod.azurecr.io/imported/library/node` |
| `library/postgres` | `hmctsprod.azurecr.io/imported/postgres` |
| `library/redis` | `hmctsprod.azurecr.io/imported/redis` |
| `library/ruby` | `hmctsprod.azurecr.io/imported/library/ruby` |
| `library/traefik` | `hmctsprod.azurecr.io/imported/traefik` |
| `linuxserver/openssh-server` | `hmctsprod.azurecr.io/imported/linuxserver/openssh-server` |
| `mailhog/mailhog` | `hmctsprod.azurecr.io/imported/mailhog/mailhog` |
| `mikefarah/yq` | `hmctsprod.azurecr.io/imported/mikefarah/yq` |
| `minio/minio` | `hmctsprod.azurecr.io/imported/minio/minio` |
| `natsio/nats-server-config-reloader` | `hmctsprod.azurecr.io/imported/natsio/nats-server-config-reloader` |
| `natsio/prometheus-nats-exporter` | `hmctsprod.azurecr.io/imported/natsio/prometheus-nats-exporter` |
| `netboxcommunity/netbox` | `hmctsprod.azurecr.io/imported/netboxcommunity/netbox` |
| `neuvector/controller` | `hmctsprod.azurecr.io/imported/neuvector/controller` |
| `neuvector/enforcer` | `hmctsprod.azurecr.io/imported/neuvector/enforcer` |
| `neuvector/manager` | `hmctsprod.azurecr.io/imported/neuvector/manager` |
| `neuvector/scanner` | `hmctsprod.azurecr.io/imported/neuvector/scanner` |
| `neuvector/updater` | `hmctsprod.azurecr.io/imported/neuvector/updater` |
| `otel/opentelemetry-collector-contrib` | `hmctsprod.azurecr.io/imported/otel/opentelemetry-collector-contrib` |
| `prom/node-exporter` | `hmctsprod.azurecr.io/imported/prom/node-exporter` |
| `testcontainers/ryuk` | `hmctsprod.azurecr.io/imported/testcontainers/ryuk` |
| `testcontainers/sshd` | `hmctsprod.azurecr.io/imported/testcontainers/sshd` |
| `toolbelt/oathtool` | `hmctsprod.azurecr.io/imported/toolbelt/oathtool` |
| `willwill/kube-slack` | `hmctsprod.azurecr.io/imported/willwill/kube-slack` |
| `williamyeh/java8` | `hmctsprod.azurecr.io/imported/williamyeh/java8` |
| `wiremock/wiremock` | `hmctsprod.azurecr.io/imported/wiremock/wiremock` |

### ACR Cache Rules

Cache rules are managed in [`acr-repositories.yaml`](acr-repositories.yaml) and applied automatically by Stage 2 of [`trivy-scan-import.yml`](trivy-scan-import.yml). See the [Stage 2 section below](#stage-2--create-and-validate-acr-cache-rules) for instructions on adding a new rule.

# Scan and Import Pipeline (`trivy-scan-import.yml`)

The [trivy-scan-import.yml](trivy-scan-import.yml) pipeline runs two stages in sequence.

## Stage 1 — Scan and Import Base Images

For each image in `baseImagestoImport`:

1. **Check version** — compares the source registry digest against the current digest in ACR. Skips the remaining steps if the image is already up to date.
2. **Scan with Trivy** — scans the source image for `CRITICAL` and `HIGH` vulnerabilities. Only runs if a new version was found.
3. **Import to ACR** — imports the image with a digest-tagged version, then re-tags it with the base tag. Only runs if the Trivy scan passed (no critical vulnerabilities).

Currently imported base images:

| Source Registry | Source Image | Tag | ACR Repository |
|-----------------|--------------|-----|----------------|
| `gcr.io` | `distroless/java25-debian13` | `latest` | `hmctsprod.azurecr.io/imported/distroless/java25` |
| `gcr.io` | `distroless/java25-debian13` | `debug` | `hmctsprod.azurecr.io/imported/distroless/java25` |
| `gcr.io` | `distroless/base-debian13` | `latest` | `hmctsprod.azurecr.io/imported/distroless/base-debian13` |
| `gcr.io` | `distroless/java21-debian12` | `latest` | `hmctsprod.azurecr.io/imported/distroless/java21` |
| `gcr.io` | `distroless/java21-debian12` | `debug` | `hmctsprod.azurecr.io/imported/distroless/java21` |
| `gcr.io` | `distroless/java17-debian12` | `latest` | `hmctsprod.azurecr.io/imported/distroless/java17` |
| `gcr.io` | `distroless/java17-debian12` | `debug` | `hmctsprod.azurecr.io/imported/distroless/java17` |
| `gcr.io` | `distroless/python3-debian13` | `latest` | `hmctsprod.azurecr.io/imported/distroless/python3` |
| `docker.io` | `jenkins/inbound-agent` | `trixie-jdk21` | `hmctsprod.azurecr.io/imported/jenkins/build-agent` |

To add a new base image, add an entry to `baseImagestoImport` in [`trivy-scan-import.yml`](trivy-scan-import.yml):

```yaml
- baseRegistry: 'gcr.io'
  baseImage: 'distroless/java25-debian13'
  baseTag: 'latest'
  targetImage: 'imported/distroless/java25'
```

## Stage 2 — Create and Validate ACR Cache Rules

Rules are read at runtime from [`acr-repositories.yaml`](acr-repositories.yaml) — this is the **single source of truth** for cache rules.

For each rule:

1. **Create cache rule** — creates the ACR cache rule if it does not already exist, mapping the upstream registry/image to a destination repository in `hmctsprod`.
2. **Check if cached image exists** — looks up the destination repository in ACR to find a tag to scan (`latest` preferred, otherwise most recent non-signature tag).
3. **Scan with Trivy** — scans the cached image already in ACR for `CRITICAL` and `HIGH` vulnerabilities. Only runs if the image exists in ACR.

ACR cache rules transparently proxy `docker pull hmctsprod.azurecr.io/<destinationRepo>:<tag>` to the upstream registry. Tags are only populated in ACR on the first pull.

To add a new cache rule, add an entry to [`acr-repositories.yaml`](acr-repositories.yaml):

```yaml
  my-image:
    ruleName: my-image          # unique rule name, minimum 5 characters
    repoName: myorg/my-image    # image path in the source registry (use library/<name> for official Docker Hub images)
    registry: docker.io         # source registry (e.g. docker.io, ghcr.io, mcr.microsoft.com, registry.k8s.io)
    destinationRepo: imported/myorg/my-image  # repository path in hmctsprod ACR
```
