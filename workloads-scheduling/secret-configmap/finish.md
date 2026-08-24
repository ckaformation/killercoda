# Bravo !

Tu viens de diagnostiquer et faire évoluer un Deployment combinant init container, Secret et ConfigMap :

1. **Diagnostic + correction** : logs de l'init container, identification d'un `mountPath` erroné, correction via `kubectl edit`.
2. **Secret + rollout** : ajout d'une clé via `stringData`, constat que ça ne suffit pas, puis `kubectl rollout restart` pour qu'un nouveau pod (et donc un nouvel init container) prenne en compte le changement.
3. **ConfigMap** : création, puis montage dans le conteneur principal via un nouveau volume et un nouveau `volumeMount`.

## Points clés à retenir

- Un init container s'exécute **une seule fois**, avant les conteneurs principaux. Modifier une ressource qu'il consomme (Secret, ConfigMap) après coup n'a aucun effet sur un pod déjà démarré : il faut un nouveau pod, donc un nouveau rollout, pour qu'il s'exécute à nouveau.
- `stringData` sur un Secret permet d'écrire des valeurs en clair ; Kubernetes les encode en base64 et les fusionne dans `data` automatiquement — plus pratique que d'éditer `data` à la main.
- Modifier le pod template d'un Deployment (ajout d'un volume, d'un volumeMount, changement d'image...) déclenche un rollout automatique. `kubectl rollout restart` sert au cas inverse : forcer un rollout **sans** changer le pod template (utile précisément quand la vraie dépendance, comme un Secret, a changé sans que Kubernetes le détecte comme un changement de spec).
- Secrets et ConfigMaps se montent de la même façon (un volume, un volumeMount) : seule la nature de la source diffère (`secret.secretName` vs `configMap.name`).

## Pour aller plus loin

- Init Containers : https://kubernetes.io/docs/concepts/workloads/pods/init-containers/
- Secrets : https://kubernetes.io/docs/concepts/configuration/secret/
- ConfigMaps : https://kubernetes.io/docs/concepts/configuration/configmap/
