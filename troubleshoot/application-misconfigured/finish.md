# Bravo !

Tu as diagnostiqué et corrigé 3 pannes distinctes, avec des symptômes
et des méthodes d'investigation différentes :

- Une référence à un `ConfigMap` inexistant (`CreateContainerConfigError`,
  visible via `kubectl describe pod`).
- Un `nodeName` pointant vers un nœud inexistant, court-circuitant le
  scheduler — le pod reste `Pending` sans aucun événement de
  planification.
- Un `serviceAccountName` inexistant, bloquant la création même du
  pod — l'erreur se voit au niveau du déploiement/replicaset, pas du
  pod.

## Pour aller plus loin

- Quelle différence de comportement observes-tu entre un `nodeName`
  invalide et un `nodeSelector` qui ne correspond à aucun nœud ? Les
  deux empêchent la planification, mais pas de la même façon.
- `kubectl get events -n <namespace> --sort-by=.lastTimestamp` :
  une vue chronologique utile quand plusieurs objets (deployment,
  replicaset, pod) sont en cause.
