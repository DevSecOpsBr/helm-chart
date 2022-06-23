# NGINX-INGRESS Helm chart for Kubernetes

Use this Helm chart to deploy the nginx-ingress-controller service to Kubernetes cluster.

## Development

Use the Helm linter to validate changes you've made to the chart:

```shell
cd helm-charts
helm lint nginx-ingress
```

## Kubernetes namespace

Services are deployed to K8s namespaces. Before we decide on whether and how
we want to automate namespace creation, you have to create the namespace for
nginx-ingress controller manually.

```shell
kubectl create ns nginx-controller
```

## Testing

Use dry-run before deploying changes to the cluster:

```shell
cd helm-charts
helm --kube-context staging-bln.liveintent.local upgrade --install nginx-ingress --dry-run --debug \
  --namespace nginx-controller \
  stable/nginx-ingress \
  -f <VALUES_ENVIRONMENT_FILE>
```

## Deployment

```shell
cd helm-charts
helm --kube-context staging-bln.liveintent.local upgrade --install nginx-ingress --debug \
  --namespace nginx-controller \
  stable/nginx-ingress \
  -f <VALUES_ENVIRONMENT_FILE>
```

## Verifying

The command above will show the output of all of ingress controller objects. To verifying wether nginx ingress controller is running follow the command.

```shell
helm --kube-context staging-bln.liveintent.local list -n nginx-controller
```

__Result:__

```text
NAME         	NAMESPACE       	REVISION	UPDATED                             	STATUS  	CHART               	APP VERSION
nginx-ingress	nginx-controller	1      	2020-02-16 15:51:38.147323 +0100 CET	deployed	nginx-ingress-1.30.0	0.28.0
```

## Enabling access log

Make sure the s3 bucket exist in advance.</br>
Use the correct annotation to specify in which bucket logs must be store.

NLB example:

```text
service.beta.kubernetes.io/aws-load-balancer-access-log-enabled: "true"
service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-name: "li-k8s-lb-ingress-logs-production"
service.beta.kubernetes.io/aws-load-balancer-access-log-s3-bucket-prefix: logs/production
service.beta.kubernetes.io/aws-load-balancer-access-log-emit-interval: "5m"
```

## Deleting

```shell
helm --kube-context staging-bln.liveintent.local uninstall nginx-ingress -n nginx-controller
```
