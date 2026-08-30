# Bravo !

Tu as :

- Créé une `StorageClass` personnalisée avec une `reclaimPolicy`
  différente de celle par défaut.
- Provisionné dynamiquement un volume via `rancher.io/local-path`, et
  observé le comportement `WaitForFirstConsumer` (le volume n'est créé
  qu'au moment où un pod le consomme réellement).
- Constaté, en conditions réelles, la différence entre `Delete` et
  `Retain` : un PV en `Retain` — et les données sur le disque du
  nœud — survit à la suppression de son `PersistentVolumeClaim`.

## Pour aller plus loin

- Regarde `kubectl get pv <nom> -o yaml` : le champ `claimRef` reste
  renseigné même après suppression du PVC, ce qui empêche le PV
  d'être automatiquement réutilisé par un nouveau PVC.
- Un PV `Released` ne redevient jamais `Available` tout seul : il faut
  intervenir manuellement (retirer `claimRef`, ou supprimer et
  recréer) pour le réutiliser.
- Compare avec un PVC utilisant la StorageClass `local-path` par
  défaut (`reclaimPolicy: Delete`) : le PV et les données disparaissent
  automatiquement à la suppression du PVC.
