# Étape 1 — Créer une StorageClass Retain

## 1. Vérifier que l'environnement est prêt

```
./wait-for-prep.sh
```{{exec}}

## 2. Créer la StorageClass

Crée une nouvelle `StorageClass` :

- nom : `retain-storage`
- même provisioner que la StorageClass par défaut : `rancher.io/local-path`
- `reclaimPolicy: Retain`
- `volumeBindingMode: WaitForFirstConsumer`

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: retain-storage
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
```

Applique-la, puis vérifie :

```
kubectl get storageclass
```{{exec}}

Tu dois voir deux `StorageClass` : `local-path` (par défaut) et
`retain-storage`.
