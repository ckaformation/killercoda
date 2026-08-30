# StorageClass et politique de rétention

Le cluster est livré avec :

- un namespace `storage`
- `rancher/local-path-provisioner` installé (namespace
  `local-path-storage`), qui provisionne des volumes dynamiques
  adossés à `/opt/local-path-provisioner` sur le nœud
- une `StorageClass` `local-path` : provisioner `rancher.io/local-path`,
  `reclaimPolicy: Delete`, `volumeBindingMode: WaitForFirstConsumer`,
  marquée comme StorageClass par défaut
  (`storageclass.kubernetes.io/is-default-class: "true"`)

Tu vas créer une seconde `StorageClass`, avec une politique de
rétention différente, et observer concrètement ce que ça change quand
un `PersistentVolumeClaim` est supprimé.

Le cluster se prépare en arrière-plan pendant que tu lis ces lignes.
