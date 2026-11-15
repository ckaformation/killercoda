# Bravo !

Tu as fourni la page de trois nginx de trois façons :

1. **`dagobah`** : l'init container `yoda` a écrit la page une seule fois, avant le démarrage de nginx, dans un volume `emptyDir`.
2. **`x-wing`** : le sidecar natif `r2-d2` réécrit la page chaque seconde, pendant que nginx la sert.
3. **`jedi-archives`** : nginx sert la page stockée sur le PVC `holocron`.

## Points clés à retenir

- Un volume se déclare dans `spec.volumes` (niveau pod) ; chaque container le monte où il veut avec `volumeMounts`. Deux containers qui montent le même volume voient les mêmes fichiers.
- `emptyDir` est créé vide au démarrage du pod et **supprimé avec lui**. Il survit au redémarrage d'un container, pas à la suppression du pod.
- Un **init container** (`spec.initContainers`) s'exécute avant les containers de l'application, un par un, et doit se terminer avec succès. Il n'est pas compté dans `READY`.
- Un **sidecar natif** est un init container avec `restartPolicy: Always` (seule valeur acceptée) : il démarre avant l'application et reste en marche pendant toute la vie du pod. Il est compté dans `READY`.
- Un pod demande un stockage persistant par le nom du **PVC** (`persistentVolumeClaim.claimName`), jamais directement par le PV.
- Monter un volume sur un répertoire masque le contenu que l'image y avait mis.

## Pour aller plus loin

- Init containers : https://kubernetes.io/docs/concepts/workloads/pods/init-containers/
- Sidecar containers : https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/
- Volumes (`emptyDir`) : https://kubernetes.io/docs/concepts/storage/volumes/#emptydir
- PersistentVolumes et PersistentVolumeClaims : https://kubernetes.io/docs/concepts/storage/persistent-volumes/
