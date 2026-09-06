# Migration de données entre StorageClass

Dans le namespace `hoth` :

- un `Deployment` `echo-base` utilise un PVC (`echo-base-data`) sur la
  StorageClass par défaut `local-path` (`reclaimPolicy: Delete`)
- une seconde StorageClass, `retain-storage` (même provisioner,
  `reclaimPolicy: Retain`), est déjà en place

Ses données doivent migrer vers un nouveau volume sur
`retain-storage` : tu vas créer le nouveau PVC, copier les données,
basculer le déploiement, puis nettoyer l'ancien volume.

Le cluster se prépare en arrière-plan pendant que tu lis ces lignes.
