#!/bin/bash

CLUSTER_DOMAIN="ellesmera.local"
DIRECTORY=$(dirname $0)
STEP="/usr/local/bin/step"
CERTS="certs"

function main() {

  $STEP certificate create identity.linkerd.$CLUSTER_DOMAIN \
    ${DIRECTORY}/$CERTS/ca.crt ${DIRECTORY}/$CERTS/ca.key --profile root-ca --no-password --insecure

  $STEP certificate create identity.linkerd.$CLUSTER_DOMAIN ${DIRECTORY}/$CERTS/issuer.crt \
    ${DIRECTORY}/$CERTS/issuer.key --ca $DIRECTORY/$CERTS/ca.crt --ca-key $DIRECTORY/$CERTS/ca.key \
    --profile intermediate-ca --not-after 8760h --no-password --insecure

}

function helm() {
  # set expiry date one year from now, in Mac:
  exp=$(date -v+8760H +"%Y-%m-%dT%H:%M:%SZ")

  helm --kube-context $CLUSTER_DOMAIN upgrade --install linkerd2 -n linkerd --debug --atomic --wait \
    --set-file global.identityTrustAnchorsPEM=$DIRECTORY/$CERTS/ca.crt \
    --set-file identity.issuer.tls.crtPEM=$DIRECTORY/$CERTS/issuer.crt \
    --set-file identity.issuer.tls.keyPEM=$DIRECTORY/$CERTS/issuer.key \
    --set identity.issuer.crtExpiry=$exp \
    .

}

if [ ! -d "${DIRECTORY}/${CERTS}" ]; then
    echo "Creating ${CERTS} directory ..."
    mkdir -p $DIRECTORY/$CERTS
else
  echo "$DIRECTORY/$CERTS exits!"
  exit;
fi

$@

# helm --kube-context ellesmera.local upgrade --install \
#   linkerd2 -n linkerd \
#   --atomic --debug --wait \
#   --set-file global.identityTrustAnchorsPEM=certs/ca.crt \
#   --set-file identity.issuer.tls.crtPEM=certs/issuer.crt \
#   --set-file identity.issuer.tls.keyPEM=certs/issuer.key \
#   --set identity.issuer.crtExpiry=2021-12-26T21:27:59Z .