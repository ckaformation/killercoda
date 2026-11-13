#!/bin/bash
VERSION=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes node01 "kubeadm version -o short" 2>/dev/null)
case "$VERSION" in
  v1.37*) ;;
  *) echo "kubeadm sur node01 n'est pas encore en v1.37.x (version actuelle: $VERSION)"; exit 1 ;;
esac
echo "kubeadm sur node01 est bien en v1.37.x."
exit 0
