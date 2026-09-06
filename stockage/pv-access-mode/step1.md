# Étape 1 — Un volume bloqué

Dans le namespace `jedi-archives`, un `PersistentVolumeClaim` reste
bloqué :

```
kubectl get pvc -n jedi-archives
```{{exec}}

Corrige la situation pour que ce PVC passe à l'état `Bound`. Aucune
autre indication ici : à toi d'investiguer.
