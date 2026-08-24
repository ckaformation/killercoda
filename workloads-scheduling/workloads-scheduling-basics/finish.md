# Bravo !

Tu viens de parcourir les trois principaux objets de charge applicative et leur mécanique de mise à jour :

1. **Pod nu** (`r2d2`) : aucun contrôleur parent, aucune auto-réparation.
2. **Deployment** (`x-wing-fleet`) : scaling (`kubectl edit`, replicas) sans nouvelle révision, puis deux modifications du pod template créant chacune une nouvelle révision, et un rollback de deux révisions en arrière avec `kubectl rollout undo --to-revision`.
3. **StatefulSet** (`jedi-archive`, `redis:7-alpine`) : modification du CPU request avec `updateStrategy: OnDelete`, nécessitant une suppression manuelle du pod pour être appliquée — y compris pour un rollback.

## Points clés à retenir

- Un Pod créé seul n'a pas de contrôleur : le supprimer, c'est le perdre définitivement.
- Seule une modification du **pod template** (`spec.template`) d'un Deployment crée une nouvelle révision — scaler (`spec.replicas`) n'en crée pas.
- `kubectl rollout undo --to-revision=N` restaure le **contenu** de la révision N, mais crée toujours un **nouveau** numéro de révision (le plus haut) : les numéros ne reculent jamais.
- `updateStrategy: OnDelete` sur un StatefulSet s'applique à **tout** changement du pod template, y compris un rollback : le contrôleur n'agit jamais de lui-même, il faut toujours supprimer le pod manuellement pour que le template en vigueur (nouveau ou restauré) soit appliqué. C'est l'inverse de `RollingUpdate` (la stratégie par défaut), qui recrée les pods automatiquement.

## Pour aller plus loin

- Deployments : https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- StatefulSets : https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
- kubectl rollout : https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/kubectl_rollout_undo/
