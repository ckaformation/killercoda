#!/bin/bash
if ! kubeadm certs check-expiration >/dev/null 2>&1; then
  echo "La commande 'kubeadm certs check-expiration' a échoué."
  exit 1
fi

if [ ! -f /etc/kubernetes/pki/apiserver.crt ]; then
  echo "/etc/kubernetes/pki/apiserver.crt est introuvable."
  exit 1
fi

if ! openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -checkend 0 >/dev/null 2>&1; then
  echo "Le certificat apiserver.crt semble déjà expiré, ce qui n'est pas attendu à ce stade."
  exit 1
fi

echo "Les certificats du control-plane sont accessibles et valides."
exit 0
