# Étape 3 — Supprimer le PVC et observer la rétention

## 1. Supprime le pod et le PVC créés à l'étape 2

```
kubectl delete pod data-pod -n storage
kubectl delete pvc data-pvc -n storage
```{{exec}}

## 2. Regarde les PersistentVolumes

```
kubectl get pv
```{{exec}}

Le `PersistentVolume` est toujours là, malgré la suppression du PVC —
c'est le rôle de `reclaimPolicy: Retain`. Avec `reclaimPolicy: Delete`
(la StorageClass `local-path` par défaut), le PV et les données
associées auraient été supprimés automatiquement.

Son statut doit être `Released` : le PV n'est plus lié à un PVC, mais
il n'est ni réutilisable automatiquement, ni supprimé.

## 3. Vérifie que les données sont toujours sur le disque

```
find /opt/local-path-provisioner -name test.txt
```{{exec}}

Le fichier `test.txt` doit toujours être présent : avec `Retain`, le
provisioner ne nettoie jamais le répertoire correspondant, même une
fois le PVC supprimé.
