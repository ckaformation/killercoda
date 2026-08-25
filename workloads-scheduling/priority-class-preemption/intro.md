# PriorityClass et Pod Preemption

Bienvenue ! Ce scénario porte sur la **priorité des pods** : comment Kubernetes décide, quand les ressources manquent, quels pods garder et lesquels sacrifier.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud.
- Trois `PriorityClass` : `level1` (priorité basse), `level2` (intermédiaire), `level3` (haute).
- Namespace **rebellion** : deux pods, `x-wing-pilot` (`level1`) et `rebel-commander` (`level2`).
- Namespace **empire** : un pod déjà en cours d'exécution, `star-destroyer` (`level2`, avec une demande mémoire de `1Gi`).
- Un pod technique, `filler`, dans le namespace `default` : il occupe volontairement une partie de la mémoire du nœud pour que l'étape 2 ait un effet réel — plus de détails dans `step2.md`.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Dans `rebellion`, identifier lequel des deux pods a la priorité la plus élevée, et le supprimer.
2. Dans `empire`, créer un nouveau pod avec une priorité supérieure à `star-destroyer` et la même demande mémoire (`1Gi`) — et observer Kubernetes **préempter** `star-destroyer` pour lui faire de la place.

C'est parti !
