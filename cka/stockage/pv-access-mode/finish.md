# Bravo !

Tu as :

- Diagnostiqué un `PersistentVolumeClaim` bloqué en `Pending` à cause
  d'une incompatibilité d'`accessModes` entre un `PersistentVolume`
  statique (`ReadOnlyMany`) et la demande du PVC (`ReadWriteOnce`) —
  un des cas classiques de blocage de binding PV/PVC.
- Déployé PostgreSQL en t'appuyant sur ce volume, en complétant un
  template partiel plutôt qu'en écrivant le manifeste de zéro.

## Pour aller plus loin

- `kubectl describe pvc holocron-storage -n jedi-archives` : regarde
  les `Events` générés pendant que le PVC était bloqué.
- Compare les `accessModes` possibles (`ReadWriteOnce`,
  `ReadOnlyMany`, `ReadWriteMany`, `ReadWriteOncePod`) et ce qu'ils
  impliquent selon le type de volume utilisé.
- `kubectl exec` dans le pod PostgreSQL et vérifie que les fichiers de
  données sont bien écrits sous `/var/lib/postgresql/data` sur le
  disque du nœud.
