# Bravo !

Tu as :

- Préparé un nœud pour une maintenance (`cordon` + `drain`) et observé
  l'effet sur un pod de `StatefulSet`.
- Ajouté une `toleration` pour permettre à un pod de tourner sur un
  nœud control-plane, normalement réservé grâce à son taint.
- Découvert que le `nodeAffinity` d'un `PersistentVolume` est une
  contrainte de placement à part entière, indépendante des taints et
  tolerations du pod — et qu'un provisioner de stockage local
  (`local-path-provisioner`) fige cette affinité sur le nœud où le
  volume a été créé.
- Recréé un volume dynamique pour qu'il se reprovisionne sur le bon
  nœud, via un cycle `scale 0` → suppression du PVC → `scale 1`.

## Pour aller plus loin

- `kubectl get pv <nom> -o yaml` : regarde le champ
  `spec.nodeAffinity` de plus près.
- Que se passerait-il avec une `StorageClass` `reclaimPolicy: Retain`
  à la place de `Delete` ? Le PV ne serait pas supprimé
  automatiquement à la suppression du PVC — la procédure de cet
  exercice ne fonctionnerait pas telle quelle.
- Ce genre de contrainte (stockage local lié à un nœud précis) est
  l'une des raisons pour lesquelles les bases de données en cluster
  sur Kubernetes utilisent souvent un stockage réseau (CSI) plutôt que
  du stockage local, quand la mobilité des pods entre nœuds est
  importante.
