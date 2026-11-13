# Bravo !

Tu as vu qu'un manifeste peut être indépendant du namespace, et que c'est le **context** qui décide où il atterrit :

1. **Context courant** : `k config current-context` indique le context utilisé, et `k config get-contexts` liste tous ceux du kubeconfig avec leur cluster, leur user et leur namespace par défaut.
2. **Un manifeste sans namespace** : `k run --dry-run=client -o yaml` n'a pas écrit de champ `namespace` dans `pod.yaml`. Le pod est donc créé dans le namespace du context courant.
3. **Changer de context** : `k config use-context endor-admin` a suffi pour que le même `k apply -f pod.yaml` crée le pod dans un autre namespace.

## Ce qu'il faut retenir

- Un context = un **cluster** + un **user** + un **namespace** par défaut. Le kubeconfig peut en contenir plusieurs, un seul est courant.
- `use-context` modifie le `current-context` du kubeconfig : le changement persiste d'une commande à l'autre, jusqu'au prochain `use-context`.
- Un nom d'objet n'est unique qu'au sein d'un namespace : deux pods `r2-d2` peuvent coexister dans `hoth` et `endor`.
- Le flag `-n` ne s'applique qu'à une commande et prend le pas sur le namespace du context. Il n'en change pas le context courant.
- Passer `-n` à `k run --dry-run=client -o yaml` écrit le namespace dans le manifeste. Un manifeste qui précise son namespace n'est plus réutilisable tel quel dans un autre : pour un fichier destiné à être appliqué dans plusieurs namespaces, génère-le sans `-n`.

## Pour aller plus loin

- Changer seulement le namespace par défaut du context courant, sans changer de context : `k config set-context --current --namespace=<ns>`.
- Documentation officielle : https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
