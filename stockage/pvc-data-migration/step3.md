# Étape 3 — Basculer et nettoyer

## 1. Mets à jour le déploiement

Modifie le déploiement `echo-base` pour qu'il monte le nouveau PVC
(`echo-base-data-retain`) au lieu de l'ancien.

```
kubectl edit deployment echo-base -n hoth
```{{exec}}

## 2. Vérifie que le pod tourne

```
kubectl get pods -n hoth
```{{exec}}

## 3. Nettoie les anciennes ressources

Une fois le pod `Running` avec le nouveau PVC, supprime le Job de
migration :

```
kubectl delete job migrate-data -n hoth
```{{exec}}

Puis supprime l'ancien PVC :

```
kubectl delete pvc echo-base-data -n hoth
```{{exec}}
