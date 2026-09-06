# Bravo !

Tu as :

- Créé un PVC sur une StorageClass différente de celle utilisée par
  l'application existante.
- Copié des données entre deux volumes via un `Job` montant les deux
  PVC simultanément.
- Basculé un `Deployment` vers un nouveau volume, puis nettoyé les
  ressources devenues inutiles (`Job`, ancien PVC).

## Pour aller plus loin

- `kubectl get pv` : compare le sort du PV de l'ancien PVC (supprimé,
  `reclaimPolicy: Delete`) et celui du nouveau (qui survivrait à une
  suppression du PVC, `reclaimPolicy: Retain`).
- Que se passerait-il avec plusieurs Gi de données ? Le `Job` de copie
  devrait tenir compte du temps nécessaire.
- Une vraie migration en production demande souvent de geler les
  écritures côté application avant de copier, pour éviter une
  incohérence entre l'ancien et le nouveau volume pendant la copie.
