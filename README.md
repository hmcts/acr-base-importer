# acr-base-importer

Pipeline to automatically import updates to base images (java) or create caching rules for 3rd party images.

## Supported Upstream Image Repositories

Below is a table of upstream image repositories that will have supported cache rules in hmctspublic. No image tags are added by default, but will be added on the first running instance of `docker pull hmctspublic.azurecr.io/${destinationRepo}:image-tag`, where destinationRepo is the [mapped repository in our ACR for the upstream repository](acr-repositories.yaml), any upstream image tag is available.


| **Upstream Repository Name**           | **HMCTS Repository Name**                                              |
|----------------------------------------|------------------------------------------------------------------------|
| `alpine`                               | `hmctspublic.azurecr.io/imported/alpine`                               |
| `bitnami/external-dns`                 | `hmctspublic.azurecr.io/imported/bitnami/external-dns`                 |
| `bitnami/kubectl`                      | `hmctspublic.azurecr.io/imported/bitnami/kubectl`                      |
| `bitnami/postgresql`                   | `hmctspublic.azurecr.io/imported/bitnami/postgresql`                   |
| `bitnami/redis`                        | `hmctspublic.azurecr.io/imported/bitnami/redis`                        |
| `datawire/tel2`                        | `hmctspublic.azurecr.io/imported/datawire/tel2`                        |
| `dius/pact-broker`                     | `hmctspublic.azurecr.io/imported/dius/pact-broker`                     |
| `drycc/service-catalog`                | `hmctspublic.azurecr.io/imported/dyrcc/service-catalog`                |
| `dynatrace/dynatrace-operator`         | `hmctspublic.azurecr.io/imported/dynatrace/dynatrace-operator`         |
| `eclipse-temurin`                      | `hmctspublic.azurecr.io/imported/eclipse-temurin`                      |
| `elastic/elasticsearch`                | `hmctspublic.azurecr.io/imported/elastic/elasticsearch`                |
| `elastic/logstash`                     | `hmctspublic.azurecr.io/imported/elastic/logstash`                     |
| `fluent/fluent-bit`                    | `hmctspublic.azurecr.io/imported/fluent/fluent-bit`                    |
| `grafana/grafana`                      | `hmctspublic.azurecr.io/imported/grafana`                              |
| `jimmidyson/configmap-reload`          | `hmctspublic.azurecr.io/imported/jimmidyson/configmap-reload`          |
| `jqlang/jq`                            | `hmctspublic.azurecr.io/imported/jqlang/jq`                            |
| `kiwigrid/k8s-sidecar`                 | `hmctspublic.azurecr.io/imported/kiwigrid/k8s-sidecar`                 |
| `kubeshop/testkube-api-server`         | `hmctspublic.azurecr.io/imported/kubeshop/testkube-api-server`         |
| `kubeshop/testkube-dashboard`          | `hmctspublic.azurecr.io/imported/kubeshop/testkube-dashboard`          |
| `kubeshop/testkube-operator`           | `hmctspublic.azurecr.io/imported/kubeshop/testkube-operator`           |
| `linuxserver/openssh-server`           | `hmctspublic.azurecr.io/imported/linuxserver/openssh-server`           |
| `mailhog/mailhog`                      | `hmctspublic.azurecr.io/imported/mailhog/mailhog`                      |
| `mikefarah/yq`                         | `hmctspublic.azurecr.io/imported/mikefarah/yq`                         |
| `minio/minio`                          | `hmctspublic.azurecr.io/imported/minio/minio`                          |
| `nats`                                 | `hmctspublic.azurecr.io/imported/nats`                                 |
| `natsio/nats-server-config-reloader`   | `hmctspublic.azurecr.io/imported/natsi/nats-server-config-reloader`    |
| `natsio/prometheus-nats-exporter`      | `hmctspublic.azurecr.io/imported/natsio/prometheus-nats-exporter`      |
| `neuvector/controller`                 | `hmctspublic.azurecr.io/imported/neuvector/controller`                 |
| `neuvector/enforcer`                   | `hmctspublic.azurecr.io/imported/neuvector/enforcer`                   |
| `neuvector/manager`                    | `hmctspublic.azurecr.io/imported/neuvector/manager`                    |
| `neuvector/scanner`                    | `hmctspublic.azurecr.io/imported/neuvector/scanner`                    |
| `neuvector/updater`                    | `hmctspublic.azurecr.io/imported/neuvector/updater`                    |
| `netboxcommunity/netbox`               | `hmctspublic.azurecr.io/imported/netboxcommunity/netbox`               |
| `nginx`                                | `hmctspublic.azurecr.io/imported/nginx`                                |
| `node`                                 | `hmctspublic.azurecr.io/imported/library/node`                         |
| `otel/opentelemetry-collector-contrib` | `hmctspublic.azurecr.io/imported/otel/opentelemetry-collector/contrib` |
| `postgres`                             | `hmctspublic.azurecr.io/imported/postgres`                             |
| `prom/node-exporter`                   | `hmctspublic.azurecr.io/imported/prom/node-exporter`                   |
| `redis`                                | `hmctspublic.azurecr.io/imported/library/redis`                        |
| `testcontainers/ryuk`                  | `hmctspublic.azurecr.io/imported/testcontainers/ryuk`                  |
| `testcontainers/sshd`                  | `hmctspublic.azurecr.io/imported/testcontainers/sshd`                  |
| `toolbelt/oathtool`                    | `hmctspublic.azurecr.io/imported/toolbelt/oathtool`                    |
| `traefik`                              | `hmctspublic.azurecr.io/imported/traefik`                              |
| `willwill/kube-slack`                  | `hmctspublic.azurecr.io/imported/willwill/kube-slack`                  |
| `williamyeh/java8`                     | `hmctspublic.azurecr.io/imported/williamyeh/java8`                     |
| `wiremock/wiremock`                    | `hmctspublic.azurecr.io/imported/wiremock/wiremock`                    |
| `azure-storage/azurite`                | `hmctspublic.azurecr.io/imported/azure-storage/azurite`                |
| `atmoz/sftp`                           | `hmctspublic.azurecr.io/imported/atmoz/sftp`                           |
| `citizensadvice/clamav-mock`           | `hmctspublic.azurecr.io/imported/citizensadvice/clamav-mock`           |
| `library/ruby`                         | `hmctspublic.azurecr.io/imported/library/ruby`                         |

### ACR Cache Rules

The pipeline will also add ACR Cache Rules into hmctspublic registry.

To create a new ACR cache rule on a repository you need to amend the [yaml file](acr-repositories.yaml), to add the required details of the new cache rule.
<br>You need to add the following block of code, replacing the values of the parameters with the one you need creating. The below is just an example of an existing ACR Cache rule

```yaml
  jenkins: # this can be the same as the name of the repository
    ruleName: Jenkins # the name of the cache rule.  Must be more than 4 characters in length.
    repoName: hmcts/jenkins # the name of the repository the image is currently stored in. Should always be format of publisher/image. If there is no publisher, please use "library".
    destinationRepo: jenkins # destination repository as it appears in the ACR Cache, will not be visibile until first instance of docker pull command
```