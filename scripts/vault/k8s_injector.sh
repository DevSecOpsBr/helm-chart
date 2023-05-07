#!/bin/bash

(
  kubectl -n security get pods
  kubectl -n security describe serviceaccount vault

  cat > vault-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: vault-token-h2kdw
  namespace: default
  annotations:
    kubernetes.io/service-account.name: vault
type: kubernetes.io/service-account-token
EOF
  kubectl apply -f vault-secret.yaml
  VAULT_HELM_SECRET_NAME=$(kubectl -n security get secrets --output=json | jq -r '.items[].metadata | select(.name|startswith("vault-token-")).name')
  kubectl -n security describe secret $VAULT_HELM_SECRET_NAME

  # Configure Kubernetes authentication
  vault auth enable kubernetes

  TOKEN_REVIEW_JWT=$(kubectl -n security get secret $VAULT_HELM_SECRET_NAME --output='go-template={{ .data.token }}' | base64 --decode)
  KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
  KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')

  vault write auth/kubernetes/config \
     token_reviewer_jwt="$TOKEN_REVIEW_JWT" \
     kubernetes_host="$KUBE_HOST" \
     kubernetes_ca_cert="$KUBE_CA_CERT" \
     issuer="https://kubernetes.default.svc.cluster.local"

  vault policy write devwebapp - <<EOF
path "secret/data/devwebapp/config" {
capabilities = ["read"]
}
EOF

  vault write auth/kubernetes/role/devweb-app \
     bound_service_account_names=internal-app \
     bound_service_account_namespaces=default \
     policies=devwebapp \
     ttl=24h

  kubectl -n default exec -it devwebapp -c app -- cat /vault/secrets/credentials.txt
)
