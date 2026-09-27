# Étape 1 — Déployer l'overlay europe-west1

L'overlay `~/kustomize-multi-region/overlays/europe-west1/` existe
déjà, mais son `ConfigMap` n'a pas encore la bonne valeur.

## 1. Positionne la région

```
vim ~/kustomize-multi-region/overlays/europe-west1/configmap-patch.yaml
```{{exec}}

Remplace `REGION: "CHANGE_ME"` par `REGION: "europe-west1"`,
enregistre et quitte (`:wq`).

## 2. Déploie l'overlay

```
kubectl apply -k ~/kustomize-multi-region/overlays/europe-west1
```{{exec}}

## 3. Vérifie

```
kubectl get pods -n europe-west1
```{{exec}}

Récupère l'IP du service et vérifie sa réponse :

```
kubectl get svc region-service -n europe-west1 -o jsonpath='{.spec.clusterIP}'
```{{exec}}

```
curl http://<cluster-ip>/
```

(remplace `<cluster-ip>` par la valeur obtenue juste au-dessus). La
réponse doit confirmer `europe-west1`.
