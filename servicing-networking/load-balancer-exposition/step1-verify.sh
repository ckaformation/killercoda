#!/bin/bash
SVC_TYPE=$(kubectl get svc holonet -n holonet -o jsonpath='{.spec.type}' 2>/dev/null)
if [ "$SVC_TYPE" != "LoadBalancer" ]; then
  echo "Le service holonet devrait être de type LoadBalancer (obtenu: '$SVC_TYPE')."
  exit 1
fi

ALLOCATE_NODEPORTS=$(kubectl get svc holonet -n holonet -o jsonpath='{.spec.allocateLoadBalancerNodePorts}' 2>/dev/null)
if [ "$ALLOCATE_NODEPORTS" != "false" ]; then
  echo "allocateLoadBalancerNodePorts devrait être à false (obtenu: '$ALLOCATE_NODEPORTS')."
  exit 1
fi

NODE_PORT=$(kubectl get svc holonet -n holonet -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
if [ -n "$NODE_PORT" ]; then
  echo "Le champ nodePort ne devrait plus être présent sur le port du service (trouvé: '$NODE_PORT')."
  exit 1
fi

EXTERNAL_IP=$(kubectl get svc holonet -n holonet -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -z "$EXTERNAL_IP" ]; then
  echo "Aucune IP externe n'a encore été attribuée par MetalLB au service holonet."
  exit 1
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://${EXTERNAL_IP}" 2>/dev/null)
if [ "$HTTP_CODE" != "200" ]; then
  echo "L'application ne répond pas via l'IP externe $EXTERNAL_IP (code obtenu: '$HTTP_CODE')."
  exit 1
fi

echo "Le service holonet est un LoadBalancer propre (sans NodePort résiduel), avec l'IP externe $EXTERNAL_IP, et répond correctement."
exit 0
