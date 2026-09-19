# Étape 2 — Où sont passés les pods ?

```
kubectl get hpa -n kessel-run
```{{exec}}

```
kubectl get pods -n kessel-run
```{{exec}}

Le HPA affiche un minimum de 10 replicas, pourtant seuls 5 pods
tournent dans le namespace. Investigue pourquoi, et corrige la
situation pour que 20 pods puissent tourner dans `kessel-run`.
