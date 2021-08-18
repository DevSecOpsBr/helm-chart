#!/bin/bash

set -a

STEP="/usr/local/bin/step"
CERTS="certs"
CHART="linkerd2"
DIRECTORY=$(dirname $0)/$CHART/$CERTS
FOLDERS=(plane issuer webhook)
OS=$(uname -s)
HOURS=8760
NS="linkerd"

function main() {

  # Trust anchor certificate
  # step certificate create root.linkerd.cluster.local ca.crt ca.key --profile root-ca --no-password --insecure 

  echo "Creating control plane certificates ..."

  $STEP certificate create root.linkerd.$CLUSTER \
    $DIRECTORY/plane/ca.crt $DIRECTORY/plane/ca.key --profile root-ca --no-password --insecure --force

    if [ $? -ne 0 ]; then 
      echo "Error creating control plane certificates!"
      exit 222
    fi

  # Issuer certificate and key
  # step certificate create identity.linkerd.cluster.local issuer.crt issuer.key \
  # --profile intermediate-ca --not-after 8760h --no-password --insecure \
  # --ca ca.crt --ca-key ca.key

  echo "Creating issuer certificates ..."

  $STEP certificate create identity.linkerd.$CLUSTER $DIRECTORY/issuer/issuer.crt $DIRECTORY/issuer/issuer.key \
    --profile intermediate-ca --not-after "$HOURS"h --no-password --insecure \
    --ca $DIRECTORY/plane/ca.crt --ca-key $DIRECTORY/plane/ca.key --force

    if [ $? -ne 0 ]; then 
      echo "Error creating issuer certificates!"
      exit 222
    fi

  # Webhook certificate
  # step certificate create webhook.linkerd.cluster.local ca.crt ca.key \
  # --profile root-ca --no-password --insecure --san webhook.linkerd.cluster.local

  echo "Creating webhook certificates ..."

  $STEP certificate create webhook.linkerd.$CLUSTER ${DIRECTORY}/webhook/ca.crt ${DIRECTORY}/webhook/ca.key \
  --profile root-ca --no-password --insecure --san webhook.linkerd.$CLUSTER --force

  if [ $? -ne 0 ]; then
    echo "Error creating webhook certificates!"
    exit 333
  fi

  certManager

}

function certManager() {

  echo "Creating tls secret ..."
  kubectl -n $NS create secret tls linkerd-trust-anchor --cert=$DIRECTORY/plane/ca.crt \
   --key=$DIRECTORY/plane/ca.key

  # deploy

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

echo "Checking OS version ..."

if [ $OS == "Darwin" ]; then
  # in Mac:
  EXP=$(date -v+${HOURS}H +"%Y-%m-%dT%H:%M:%SZ")
  echo "Updating certificate expiry"
  sed -i '' "s/__replaceme__/${EXP}/g" helmsman.yaml
else
  # in Linux:
  EXP=$(date -d \'+${HOURS} hour\' +"%Y-%m-%dT%H:%M:%SZ")
  echo "Updating certificate expiry"
  sed -i '' "s/__replaceme__/${EXP}/g" helmsman.yaml
fi

$@
