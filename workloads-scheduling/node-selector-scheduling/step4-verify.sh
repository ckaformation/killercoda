#!/bin/bash
if [ -f /etc/kubernetes/manifests/kube-scheduler.yaml ]; then
  echo "kube-scheduler.yaml est encore dans /etc/kubernetes/manifests : le scheduler n'est pas arrêté."
  exit 1
fi

if kubectl get pods -n kube-system -l component=kube-scheduler --no-headers 2>/dev/null | grep -q .; then
  echo "Le pod kube-scheduler existe encore dans kube-system."
  exit 1
fi

if ! kubectl get pod vader >/dev/null 2>&1; then
  echo "Le pod vader n'existe pas encore."
  exit 1
fi

NODE=$(kubectl get pod vader -o jsonpath='{.spec.nodeName}' 2>/dev/null)
if [ "$NODE" != "node01" ]; then
  echo "Le pod vader devrait avoir nodeName=node01 (obtenu: '$NODE')."
  exit 1
fi

if ! kubectl wait --for=condition=Ready pod/vader --timeout=60s >/dev/null 2>&1; then
  echo "Le pod vader n'est pas encore Ready."
  exit 1
fi

echo "Le kube-scheduler est arrêté, et le pod vader tourne bien sur node01 malgré tout."
exit 0
