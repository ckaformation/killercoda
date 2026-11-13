# Étape 1 — Créer le nouveau PVC

Le déploiement `echo-base` (namespace `hoth`) utilise un PVC sur la
StorageClass par défaut (`local-path`, `reclaimPolicy: Delete`). Ses
données doivent migrer vers un nouveau PVC, sur la StorageClass
`retain-storage` (déjà créée, `reclaimPolicy: Retain`).

Crée ce nouveau PVC dans le namespace `hoth` :

- taille : `1Gi`
- accessMode : `ReadWriteOnce`
- `storageClassName: retain-storage`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: echo-base-data-retain
  namespace: hoth
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: retain-storage
  resources:
    requests:
      storage: 1Gi
```

```
kubectl get pvc -n hoth
```{{exec}}

Avec `volumeBindingMode: WaitForFirstConsumer`, ce nouveau PVC reste en
`Pending` tant qu'aucun pod ne le monte — c'est normal, ce sera réglé
à l'étape suivante.
