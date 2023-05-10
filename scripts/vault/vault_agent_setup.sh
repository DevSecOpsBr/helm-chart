#!/bin/bash

  vault auth enable kubernetes
  vault secrets enable -path=secret kv
  vault kv put secret/devwebapp/config username="giraffe" password="salsa"
  vault kv get -format=json secret/devwebapp/config | jq ".data"

  kubectl -n default create sa devwebapp-app
  kubectl -n default get pods

  kubectl -n security describe serviceaccount vault
  VAULT_TOKEN=$(kubectl -n security get sa vault -ojsonpath="{.secrets}" | awk -F '"' '{print $4}')

  tee vault-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $VAULT_TOKEN
  namespace: default
  annotations:
    kubernetes.io/service-account.name: vault
type: kubernetes.io/service-account-token
EOF
  kubectl apply -f vault-secret.yaml
  rm vault-secret.yaml

  export VAULT_HELM_SECRET_NAME=$(kubectl -n security get secrets --output=json | jq -r '.items[].metadata | select(.name|startswith("vault-token-")).name')
  export TOKEN_REVIEW_JWT=$(kubectl -n security get secret $VAULT_HELM_SECRET_NAME --output='go-template={{ .data.token }}' | base64 --decode)
  export KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
  export KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')
  kubectl -n security describe secret $VAULT_HELM_SECRET_NAME

  exit 0;

  vault write auth/kubernetes/config \
     token_reviewer_jwt="$(echo $TOKEN_REVIEW_JWT)" \
     kubernetes_host="$(echo $KUBE_HOST)" \
     kubernetes_ca_cert="$(echo $KUBE_CA_CERT)" \
     issuer="https://kubernetes.default.svc.cluster.local"

  vault policy write devwebapp - <<EOF
path "secret/*" {
capabilities = ["read"]
}
EOF

  vault write auth/kubernetes/role/devweb-app \
     bound_service_account_names=devwebapp-app \
     bound_service_account_namespaces=default \
     policies=devwebapp \
     ttl=24h

  kubectl apply -f devwebapp.yaml
  kubectl -n default get sa,deploy,svc,pod -owide


