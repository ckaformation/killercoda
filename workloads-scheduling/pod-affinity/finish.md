# Bravo !

Tu viens d'explorer la pod affinity, un mécanisme de placement relatif — "sur le même nœud qu'un autre pod" — plutôt qu'absolu comme `nodeSelector` ou les taints :

1. **Découverte de l'immuabilité** : `spec.affinity` (comme la plupart des champs d'un `Pod`) ne peut pas être modifié sur un pod déjà créé — il faut le supprimer et le recréer avec la nouvelle spec, généralement à partir de son fichier YAML.
2. **Pod affinity** : `luke` configuré pour se placer sur le même nœud qu'un pod portant `app=yoda`, via `requiredDuringSchedulingIgnoredDuringExecution` et `topologyKey: kubernetes.io/hostname`.
3. **Effet relatif, pas figé** : en changeant uniquement l'emplacement de `yoda` (via son `nodeName`) et en recréant les deux pods dans le bon ordre, `luke` a suivi automatiquement — sans qu'on retouche sa propre configuration.

## Points clés à retenir

- Un `Pod` est très majoritairement **immuable** après création : contrairement à un `Deployment` ou un `StatefulSet`, qui gèrent le remplacement des pods pour toi, un pod nu doit être supprimé puis recréé pour tout changement substantiel de sa spec.
- `topologyKey: kubernetes.io/hostname` signifie "le même nœud, exactement" — d'autres valeurs de `topologyKey` (basées sur des labels de région, de zone...) permettraient des contraintes moins strictes, à l'échelle d'un groupe de nœuds plutôt que d'un seul.
- L'**ordre de création** compte avec `requiredDuringSchedulingIgnoredDuringExecution` : le pod cible de l'affinité (ici `yoda`) doit déjà être schedulé pour que le pod affine (ici `luke`) puisse être placé immédiatement.
- `IgnoredDuringExecution` (dans le nom du champ) signifie que cette contrainte n'est vérifiée qu'au moment du scheduling : si le pod cible disparaît ou change de nœud *après coup*, les pods déjà en cours d'exécution ne sont pas déplacés automatiquement pour autant — exactement ce que ce scénario a démontré en forçant la recréation des deux pods à l'étape 2.

## Pour aller plus loin

- Affinity and anti-affinity : https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity
