# Étape 3 — Retirer le Service depuis base

L'équipe applicative décide que le `Service` n'est plus nécessaire.
Retire-le au niveau de `base`, pour que ce choix s'applique aux deux
overlays.

## 1. Retire la ressource service.yaml de base

Édite `base/kustomization.yaml` et retire la ligne `- service.yaml`
de la liste `resources:` :

```
vim ~/kustomize-multi-region/base/kustomization.yaml
```{{exec}}

Tu peux aussi, en plus, supprimer le fichier lui-même (il ne sera de
toute façon plus utilisé une fois qu'il n'est plus référencé) :

```
rm ~/kustomize-multi-region/base/service.yaml
```{{exec}}

## 2. Réapplique les deux overlays

```
kubectl apply -k ~/kustomize-multi-region/overlays/europe-west1
```{{exec}}

```
kubectl apply -k ~/kustomize-multi-region/overlays/us-west1
```{{exec}}

## 3. Observe

```
kubectl get svc -n europe-west1
```{{exec}}

Le `Service` `region-service` est encore là. `kubectl apply -k` ne
supprime jamais une ressource simplement parce qu'elle a disparu du
manifest : il faut la supprimer explicitement.

## 4. Nettoie les deux namespaces

```
kubectl delete svc region-service -n europe-west1
```{{exec}}

```
kubectl delete svc region-service -n us-west1
```{{exec}}
