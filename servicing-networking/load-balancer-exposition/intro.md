# MetalLB : exposer un service en LoadBalancer, puis l'autoscaler

Bienvenue ! Sur un cluster cloud, un `Service` de type `LoadBalancer` provisionne automatiquement une IP externe auprès du fournisseur cloud. Sur un cluster "bare metal" (ou ici, une VM Killercoda), il n'y a pas de cloud pour faire ce travail — c'est le rôle de **MetalLB**.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud.
- **MetalLB**, installé et configuré en mode L2 (annonces ARP), avec une plage d'adresses dérivée dynamiquement du sous-réseau réel du nœud (par exemple `172.30.1.100-172.30.1.110` si le nœud est en `172.30.1.x` — la plage exacte dépend de l'environnement).
- **metrics-server**, nécessaire pour que le `HorizontalPodAutoscaler` de l'étape 2 dispose de vraies métriques CPU, plutôt que d'afficher indéfiniment `<unknown>`.
- Une application, `holonet`, dans son propre namespace applicatif (également nommé `holonet`) : un `Deployment` (2 réplicas, avec une demande CPU définie sur chaque pod) exposé par un `Service` de type **NodePort**.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Faire passer le `Service` `holonet` de `NodePort` à `LoadBalancer`, et vérifier que l'application répond bien sur l'IP externe attribuée par MetalLB.
2. Ajouter un `HorizontalPodAutoscaler` sur le `Deployment` `holonet` (2 à 4 réplicas, déclenché à 50% d'utilisation CPU moyenne).

> Note honnête sur l'étape 2 : le lien entre "exposer un service en LoadBalancer" et "ajouter un HPA" n'est pas un lien technique strict — un HPA fonctionne aussi bien derrière un `ClusterIP` ou un `NodePort`. C'est plutôt une bonne pratique complémentaire et réaliste : un service exposé vers l'extérieur est justement le genre de service pour lequel on veut absorber des pics de trafic élastiquement. On en profite ici pour pratiquer la mise en place d'un HPA, dans la continuité du chapitre Services & Networking.

C'est parti !
