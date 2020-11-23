# HELM

This README shows how to check `deprecated` charts and how to install multiple charts at once based on `YAML` files.

### Requirements:

1. Pluto
2. Reckoner

# Pluto

Pluto easily find deprecated Kubernetes API versions in their Infrastructure-as-Code repositories and Helm releases.

## Examples

### In directory

```shell
pluto detect-files -d cert-manager
```

_Output:_
```text
NAME                                  KIND                       VERSION                        REPLACEMENT               REMOVED   DEPRECATED
certificaterequests.cert-manager.io   CustomResourceDefinition   apiextensions.k8s.io/v1beta1   apiextensions.k8s.io/v1   false     true
certificates.cert-manager.io          CustomResourceDefinition   apiextensions.k8s.io/v1beta1   apiextensions.k8s.io/v1   false     true
challenges.acme.cert-manager.io       CustomResourceDefinition   apiextensions.k8s.io/v1beta1   apiextensions.k8s.io/v1   false     true
clusterissuers.cert-manager.io        CustomResourceDefinition   apiextensions.k8s.io/v1beta1   apiextensions.k8s.io/v1   false     true
issuers.cert-manager.io               CustomResourceDefinition   apiextensions.k8s.io/v1beta1   apiextensions.k8s.io/v1   false     true
orders.acme.cert-manager.io           CustomResourceDefinition   apiextensions.k8s.io/v1beta1   apiextensions.k8s.io/v1   false     true
```

### In cluster

```shell
pluto detect-helm -owide
```

_Output:_

```text
NAME                                               KIND                           VERSION                                REPLACEMENT                       REMOVED   DEPRECATED
cert-manager/cert-manager-webhook                  MutatingWebhookConfiguration   admissionregistration.k8s.io/v1beta1   admissionregistration.k8s.io/v1   false     true
keel/keel                                          Ingress                        extensions/v1beta1                     networking.k8s.io/v1beta1         false     true
kubeopsview/kubeopsview-kube-ops-view              Ingress                        extensions/v1beta1                     networking.k8s.io/v1beta1         false     true
prometheus/prometheus-prometheus-oper-prometheus   Ingress                        extensions/v1beta1                     networking.k8s.io/v1beta1         false     true
prometheus/prometheus-prometheus-oper-admission    MutatingWebhookConfiguration   admissionregistration.k8s.io/v1beta1   admissionregistration.k8s.io/v1   false     true
```

### In cluster version

```shell
pluto detect-helm -t k8s=v1.15.10
```

_Output:_

```text
NAME                                               KIND      VERSION              REPLACEMENT                 REMOVED   DEPRECATED
keel/keel                                          Ingress   extensions/v1beta1   networking.k8s.io/v1beta1   false     true
kubeopsview/kubeopsview-kube-ops-view              Ingress   extensions/v1beta1   networking.k8s.io/v1beta1   false     true
prometheus/prometheus-prometheus-oper-prometheus   Ingress   extensions/v1beta1   networking.k8s.io/v1beta1   false     true
```

# Reckoner

Reckoner is a command line helper for Helm that uses a YAML syntax to install and manage multiple Helm charts in a single file and allows installation of charts from a git commit/branch/release.

### What it solves?

* Kubernetes namespace creation
* Multiple charts installation at once
* Custom values YAML file per section

`course.yaml` file

```yaml
namespace: default
context: ellesmera.local

charts:
  metrics-server:
    repository: stable
    chart: metrics-server
    namespace: monitoring
    namespace_management:
      metadata:
        annotations:
          iam.amazonaws.com/permitted: .*
      settings:
        overwrite: True
    hooks:
      pre_install:
        - helm -n monitoring list
      post_install:
        - helm -n monitoring list
    files: 
      - metrics-server/values.yaml

  prometheus:
    repository: stable
    chart: prometheus-operator
    version: 8.12.12
    namespace: monitoring
    namespace_management:
      metadata:
        annotations:
          iam.amazonaws.com/permitted: .*
      settings:
        overwrite: True
    hooks:
      pre_install:
        - helm -n monitoring list
      post_install:
        - helm -n monitoring list
    files: 
      - prometheus-operator/values.yaml

  jaeger:
    repository: stable
    chart: jaeger-operator
    namespace: observability
    namespace_management:
      metadata:
        annotations:
          iam.amazonaws.com/permitted: .*
      settings:
        overwrite: True
    hooks:
      pre_install:
        - helm -n observability list
      post_install:
        - helm -n observability list
    files: 
      - jaeger-operator/values.yaml

  nginx:
    repository: stable
    chart: nginx-ingress
    namespace: ingress-controller
    namespace_management:
      metadata:
        annotations:
          iam.amazonaws.com/permitted: .*
      settings:
        overwrite: True
    hooks:
      pre_install:
        - helm -n ingress-controller list
      post_install:
        - helm -n ingress-controller list
    files: 
      - nginx-ingress/values.yaml

  kubeopsview:
    repository: stable
    chart: kube-ops-view
    namespace: monitoring
    namespace_management:
      metadata:
        annotations:
          iam.amazonaws.com/permitted: .*
      settings:
        overwrite: True
    hooks:
      pre_install:
        - helm -n monitoring list
      post_install:
        - helm -n monitoring list
    files: 
      - kube-ops-view/values.yaml

  polaris-dashboard:
    namespace: security
    repository: stable
    chart: polaris
    hooks:
      pre_install:
        - helm -n security list
      post_install:
        - helm -n security list
    files:
      - polaris/values.yaml

```

In action:

```shell
reckoner plot --dry-run -a course.yaml
```

_Output:_

```text
NAME            NAMESPACE               REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
cert-manager    cert-manager            1               2020-11-17 20:37:08.825754 +0100 CET    deployed        cert-manager-v0.13.0            v0.13.0
hellofresh      default                 3               2020-11-20 17:18:07.042306 +0100 CET    deployed        hellofresh-1.0.0                1.0.0
jaeger          observability           1               2020-11-17 20:20:55.072396 +0100 CET    deployed        jaeger-operator-2.14.0          1.17.0
keel            miscellaneous           4               2020-11-20 19:23:55.028413 +0100 CET    deployed        keel-0.8.19                     0.16.0
kubeopsview     monitoring              1               2020-11-23 09:57:18.335906 +0100 CET    deployed        kube-ops-view-1.2.4             20.4.0
metrics-server  monitoring              1               2020-11-17 20:14:44.908651 +0100 CET    deployed        metrics-server-2.9.0            0.3.6
nginx           ingress-controller      1               2020-11-17 20:32:58.637503 +0100 CET    deployed        nginx-ingress-1.36.3            0.30.0
oauth2-proxy    default                 1               2020-11-23 14:44:08.714642 +0100 CET    deployed        oauth2-proxy-3.2.5              5.1.0
pomerium        security                3               2020-11-17 22:39:25.985695 +0100 CET    deployed        pomerium-13.1.3                 0.10.6
prometheus      monitoring              1               2020-11-17 20:05:48.026192 +0100 CET    deployed        prometheus-operator-8.12.12     0.37.0
```

# Bottlenecks

Reckoner points to a custom `values`YAML file to install charts. Even if reckoner is not available `helm` can be used to instead.

For instance:

```shell
helm --kube-context <cluster-context> <plugin> upgrade --install <release-name> -n <namespace> -f <custom-values-file> --debug --wait  <helm repo>/<chart name> --dry-run* --version* --set AppVersion*
```

# Similar tools 

The tools below has a similar behaivour wrapping `terraform` to extend his capabilities and gaps.

* [Terragrunt](http://https://terragrunt.gruntwork.io/)
* [Run Atlantis](http://runatlantis.io)
