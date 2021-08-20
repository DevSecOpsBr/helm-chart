#!/bin/bash

set -a

STEP="/usr/local/bin/step"
CERTS="certs"
CHART="linkerd2"
DIRECTORY=$(dirname $0)/$CHART/$CERTS
FOLDERS=(plane issuer webhook)
NS="linkerd"

function main() {

  # Trust anchor certificate
  echo "Creating control plane certificates ..."

  $STEP certificate create root.linkerd.$CLUSTER \
    $DIRECTORY/plane/ca.crt $DIRECTORY/plane/ca.key --profile root-ca --no-password --insecure --force

    if [ $? -ne 0 ]; then 
      echo "Error creating control plane certificates!"
      exit 222
    fi

  # Issuer certificate and key
  echo "Creating issuer certificates ..."

  $STEP certificate create identity.linkerd.$CLUSTER $DIRECTORY/issuer/issuer.crt $DIRECTORY/issuer/issuer.key \
    --profile intermediate-ca --not-after "$HOURS"h --no-password --insecure \
    --ca $DIRECTORY/plane/ca.crt --ca-key $DIRECTORY/plane/ca.key --force

    if [ $? -ne 0 ]; then 
      echo "Error creating issuer certificates!"
      exit 222
    fi

  # Webhook certificate
  echo "Creating webhook certificates ..."

  $STEP certificate create webhook.linkerd.$CLUSTER ${DIRECTORY}/webhook/ca.crt ${DIRECTORY}/webhook/ca.key \
  --profile root-ca --no-password --insecure --san webhook.linkerd.$CLUSTER --force

  if [ $? -ne 0 ]; then
    echo "Error creating webhook certificates!"
    exit 333
  fi

  secrets

}

function secrets() {

    echo "Creating secret tls ..."
    kubectl -n $NS create secret tls linkerd-trust-anchor --cert=$DIRECTORY/plane/ca.crt --key=$DIRECTORY/plane/ca.key
    echo "linkerd-trust-anchor, created ..."
    kubectl -n $NS create secret tls webhook-issuer-tls --cert=$DIRECTORY/plane/ca.crt --key=$DIRECTORY/plane/ca.key
    echo "webhook-issuer-tls, created ..."
    kubectl -n $NS create secret tls linkerd-identity-issuer --cert=$DIRECTORY/issuer/issuer.crt --key=$DIRECTORY/issuer/issuer.key
    echo "linkerd-identity-issuer, created ..."

}

function cleanUp() {

    if [[ -d $DIRECTORY ]]; then
      echo "Removing certificates ..."
      rm -rf $DIRECTORY
    fi

}

if [ ! -d "${DIRECTORY}/${CERTS}" ]; then
    echo "Creating ${CERTS} directory ..."
    for f in ${FOLDERS[@]}; do 
      mkdir -p $DIRECTORY/$f
    done
else
  echo "$DIRECTORY/$CERTS exits!"
  exit;
fi

$@
