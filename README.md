# acr-base-importer

Pipeline to automatically import updates to base images (java) or create caching rules for 3rd party images.

## Supported Upstream Image Repositories

Below is a table of upstream image repositories that will have supported cache rules in hmctsprod. No image tags are added by default, but will be added on the first running instance of `docker pull hmctsprod.azurecr.io/${destinationRepo}:image-tag`, where destinationRepo is the [mapped repository in our ACR for the upstream repository](acr-repositories.yaml), any upstream image tag is available.


| **Upstream Repository Name**           | **HMCTS Repository Name**                                              |
|----------------------------------------|------------------------------------------------------------------------|
| `alpine`                               | `hmctsprod.azurecr.io/imported/alpine`                               |
| `bitnami/external-dns`                 | `hmctsprod.azurecr.io/imported/bitnami/external-dns`                 |
| `bitnami/kubectl`                      | `hmctsprod.azurecr.io/imported/bitnami/kubectl`                      |
| `bitnami/postgresql`                   | `hmctsprod.azurecr.io/imported/bitnami/postgresql`                   |
| `bitnami/redis`                        | `hmctsprod.azurecr.io/imported/bitnami/redis`                        |
| `datawire/tel2`                        | `hmctsprod.azurecr.io/imported/datawire/tel2`                        |
| `dius/pact-broker`                     | `hmctsprod.azurecr.io/imported/dius/pact-broker`                     |
| `drycc/service-catalog`                | `hmctsprod.azurecr.io/imported/dyrcc/service-catalog`                |
| `dynatrace/dynatrace-operator`         | `hmctsprod.azurecr.io/imported/dynatrace/dynatrace-operator`         |
| `eclipse-temurin`                      | `hmctsprod.azurecr.io/imported/eclipse-temurin`                      |
| `elastic/elasticsearch`                | `hmctsprod.azurecr.io/imported/elastic/elasticsearch`                |
| `elastic/logstash`                     | `hmctsprod.azurecr.io/imported/elastic/logstash`                     |
| `fluent/fluent-bit`                    | `hmctsprod.azurecr.io/imported/fluent/fluent-bit`                    |
| `grafana/grafana`                      | `hmctsprod.azurecr.io/imported/grafana`                              |
| `jimmidyson/configmap-reload`          | `hmctsprod.azurecr.io/imported/jimmidyson/configmap-reload`          |
| `jqlang/jq`                            | `hmctsprod.azurecr.io/imported/jqlang/jq`                            |
| `kiwigrid/k8s-sidecar`                 | `hmctsprod.azurecr.io/imported/kiwigrid/k8s-sidecar`                 |
| `kubeshop/testkube-api-server`         | `hmctsprod.azurecr.io/imported/kubeshop/testkube-api-server`         |
| `kubeshop/testkube-dashboard`          | `hmctsprod.azurecr.io/imported/kubeshop/testkube-dashboard`          |
| `kubeshop/testkube-operator`           | `hmctsprod.azurecr.io/imported/kubeshop/testkube-operator`           |
| `linuxserver/openssh-server`           | `hmctsprod.azurecr.io/imported/linuxserver/openssh-server`           |
| `mailhog/mailhog`                      | `hmctsprod.azurecr.io/imported/mailhog/mailhog`                      |
| `mikefarah/yq`                         | `hmctsprod.azurecr.io/imported/mikefarah/yq`                         |
| `minio/minio`                          | `hmctsprod.azurecr.io/imported/minio/minio`                          |
| `nats`                                 | `hmctsprod.azurecr.io/imported/nats`                                 |
| `natsio/nats-server-config-reloader`   | `hmctsprod.azurecr.io/imported/natsi/nats-server-config-reloader`    |
| `natsio/prometheus-nats-exporter`      | `hmctsprod.azurecr.io/imported/natsio/prometheus-nats-exporter`      |
| `neuvector/controller`                 | `hmctsprod.azurecr.io/imported/neuvector/controller`                 |
| `neuvector/enforcer`                   | `hmctsprod.azurecr.io/imported/neuvector/enforcer`                   |
| `neuvector/manager`                    | `hmctsprod.azurecr.io/imported/neuvector/manager`                    |
| `neuvector/scanner`                    | `hmctsprod.azurecr.io/imported/neuvector/scanner`                    |
| `neuvector/updater`                    | `hmctsprod.azurecr.io/imported/neuvector/updater`                    |
| `netboxcommunity/netbox`               | `hmctsprod.azurecr.io/imported/netboxcommunity/netbox`               |
| `nginx`                                | `hmctsprod.azurecr.io/imported/nginx`                                |
| `node`                                 | `hmctsprod.azurecr.io/imported/library/node`                         |
| `otel/opentelemetry-collector-contrib` | `hmctsprod.azurecr.io/imported/otel/opentelemetry-collector/contrib` |
| `postgres`                             | `hmctsprod.azurecr.io/imported/postgres`                             |
| `prom/node-exporter`                   | `hmctsprod.azurecr.io/imported/prom/node-exporter`                   |
| `redis`                                | `hmctsprod.azurecr.io/imported/library/redis`                        |
| `testcontainers/ryuk`                  | `hmctsprod.azurecr.io/imported/testcontainers/ryuk`                  |
| `testcontainers/sshd`                  | `hmctsprod.azurecr.io/imported/testcontainers/sshd`                  |
| `toolbelt/oathtool`                    | `hmctsprod.azurecr.io/imported/toolbelt/oathtool`                    |
| `traefik`                              | `hmctsprod.azurecr.io/imported/traefik`                              |
| `willwill/kube-slack`                  | `hmctsprod.azurecr.io/imported/willwill/kube-slack`                  |
| `williamyeh/java8`                     | `hmctsprod.azurecr.io/imported/williamyeh/java8`                     |
| `wiremock/wiremock`                    | `hmctsprod.azurecr.io/imported/wiremock/wiremock`                    |
| `azure-storage/azurite`                | `hmctsprod.azurecr.io/imported/azure-storage/azurite`                |
| `atmoz/sftp`                           | `hmctsprod.azurecr.io/imported/atmoz/sftp`                           |
| `citizensadvice/clamav-mock`           | `hmctsprod.azurecr.io/imported/citizensadvice/clamav-mock`           |
| `library/ruby`                         | `hmctsprod.azurecr.io/imported/library/ruby`                         |

### ACR Cache Rules

The pipeline will also add ACR Cache Rules into hmctsprod registry.

To create a new ACR cache rule on a repository you need to amend the following two files.

[acr-repositories.yaml](acr-repositories.yaml)
<br>You need to add the following block of code, replacing the values of the parameters with the one you need creating. The below is just an example of an existing ACR Cache rule

```yaml
  jenkins: # this can be the same as the name of the repository
    ruleName: Jenkins # the name of the cache rule.  Must be more than 4 characters in length.
    repoName: hmcts/jenkins # the name of the repository the image is currently stored in. Should always be format of publisher/image. If there is no publisher, please use "library".
    destinationRepo: jenkins # destination repository as it appears in the ACR Cache, will not be visibile until first instance of docker pull command
```
[trivy-scan-import.yml](trivy-scan-import.yml)
<br>You need to add the following block of code under the parameter `parameters.cacheRulesToValidate.default`.

```yaml
      ruleName: 'postgresql'
      baseRegistry: 'docker.io'
      baseImage: 'bitnami/postgresql'
      destinationRepo: 'imported/bitnami/postgresql'
```
