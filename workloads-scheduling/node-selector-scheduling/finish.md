# Bravo !

Tu viens d'explorer le scheduling Kubernetes sous plusieurs angles :

1. **Labels de nœuds** : un label commun aux deux nœuds, puis un label spécifique à un seul.
2. **nodeSelector** : deux Deployments avec des contraintes de placement différentes, l'une large (un seul label), l'autre stricte (deux labels combinés).
3. **Conséquence d'un retrait de label** : `nodeSelector` n'est évalué qu'au moment du scheduling, pas en continu — retirer un label ne bouge rien tant qu'un nouveau rollout n'est pas déclenché.
4. **Le rôle exact du kube-scheduler** : en l'arrêtant, puis en assignant un pod à un nœud via `nodeName`, tu as vu que le scheduler ne fait qu'une seule chose — choisir `nodeName` pour les pods qui ne l'ont pas déjà. Une fois cette valeur posée, par n'importe quel moyen, le kubelet du nœud concerné prend le relais tout seul.

## Points clés à retenir

- `nodeSelector` est une contrainte évaluée **une fois**, au moment où le pod est créé (ou recréé) — pas un mécanisme de réconciliation continue comme un `nodeSelector` qui "suivrait" les changements de labels des nœuds.
- Modifier les labels d'un nœud n'affecte donc que les **futurs** placements, jamais les pods déjà en cours d'exécution ailleurs.
- `spec.nodeName`, positionné directement, court-circuite entièrement le scheduler : c'est exactement le mécanisme que le scheduler utilise lui-même en interne une fois sa décision prise.
- Arrêter le `kube-scheduler` (contrairement à `kube-apiserver` ou `etcd`) n'a aucun impact sur les pods déjà en cours d'exécution ni sur `kubectl` : seuls les nouveaux pods sans nœud assigné en pâtissent.

## Pour aller plus loin

- Assigning Pods to Nodes : https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
- kube-scheduler : https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/
