# Bravo !

Tu viens de diagnostiquer et corriger deux pannes `NetworkPolicy` classiques, sans instructions pas à pas :

1. **matchLabels erroné** : une `NetworkPolicy` syntaxiquement valide, qui semble correcte à première lecture, mais référence une valeur de label qui ne correspond à rien de réel — un cas très fréquent en production (copier-coller mal adapté, label renommé sans mettre à jour la policy qui le référence...).
2. **ET au lieu de OU** : la nuance d'indentation entre `namespaceSelector`/`podSelector` combinés dans le même élément de liste (ET) ou séparés en deux éléments (OU) — une source d'erreur silencieuse extrêmement courante, puisque YAML ne signale aucune erreur de syntaxe dans les deux cas : les deux versions sont parfaitement valides, seul leur sens diffère.

## Réflexe de diagnostic à retenir

Face à une `NetworkPolicy` qui ne se comporte pas comme prévu :

1. Relis la policy en détail (`kubectl get networkpolicy ... -o yaml`), en particulier l'indentation exacte des sélecteurs.
2. Compare les valeurs attendues aux labels **réellement présents** (`kubectl get ns --show-labels`, `kubectl get pods --show-labels`) — ne suppose jamais qu'un label existe sans le vérifier.
3. Teste avec `kubectl exec ... -- curl` pour confirmer le comportement réel, avant et après correction.

## Pour aller plus loin

- Network Policies : https://kubernetes.io/docs/concepts/services-networking/network-policies/
