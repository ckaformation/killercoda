# Bravo !

Tu viens de manipuler deux briques essentielles de l'exposition et du scaling d'une application :

1. **MetalLB + LoadBalancer** : sur un cluster sans cloud provider, MetalLB comble le vide en attribuant de vraies IP externes aux `Service` de type `LoadBalancer`, annoncées sur le réseau local via ARP (mode L2).
2. **HorizontalPodAutoscaler** : un `Deployment` peut ajuster son nombre de réplicas automatiquement, entre un minimum et un maximum, en fonction d'une métrique réelle (ici, l'utilisation CPU moyenne) — à condition que `metrics-server` soit en place pour fournir ces métriques.

## Points clés à retenir

- Sans un contrôleur comme MetalLB, un `Service` de type `LoadBalancer` reste indéfiniment `<pending>` sur un cluster bare-metal/on-prem — ce n'est pas Kubernetes qui provisionne l'IP, mais un composant tiers.
- Le mode L2 de MetalLB est le plus simple à mettre en place (pas de routeur BGP à configurer), mais tout le trafic pour une IP donnée transite par un seul nœud à la fois — un vrai partage de charge réseau nécessiterait le mode BGP.
- Un HPA basé sur `averageUtilization` a besoin de deux choses pour fonctionner : une demande de ressource (`requests.cpu`) définie sur les pods ciblés, comme base de calcul du pourcentage, et `metrics-server` (ou un autre fournisseur de métriques) installé dans le cluster.
- `minReplicas`/`maxReplicas` bornent l'intervalle dans lequel le HPA peut faire varier le nombre de réplicas — mais n'imposent aucune action tant que la métrique surveillée reste dans la cible.

## Pour aller plus loin

- MetalLB : https://metallb.universe.tf/
- Horizontal Pod Autoscaling : https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- metrics-server : https://github.com/kubernetes-sigs/metrics-server
