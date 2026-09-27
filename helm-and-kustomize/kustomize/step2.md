# Étape 2 — Ajouter l'overlay us-west1

Crée un second overlay pour `us-west1`, en copiant l'existant. Seuls
`kustomization.yaml` et le `ConfigMap` ont besoin de changer.

## 1. Copie l'overlay europe-west1

```
mkdir -p ~/kustomize-multi-region/overlays/us-west1
```{{exec}}

```
cp ~/kustomize-multi-region/overlays/europe-west1/kustomization.yaml ~/kustomize-multi-region/overlays/us-west1/
```{{exec}}

```
cp ~/kustomize-multi-region/overlays/europe-west1/configmap-patch.yaml ~/kustomize-multi-region/overlays/us-west1/
```{{exec}}

## 2. Adapte les 2 fichiers copiés

```
vim ~/kustomize-multi-region/overlays/us-west1/kustomization.yaml
```{{exec}}

Change `namespace: europe-west1` en `namespace: us-west1`, enregistre
et quitte (`:wq`).

```
vim ~/kustomize-multi-region/overlays/us-west1/configmap-patch.yaml
```{{exec}}

Change `REGION: "europe-west1"` en `REGION: "us-west1"`, enregistre
et quitte (`:wq`).

## 3. Déploie et vérifie

```
kubectl apply -k ~/kustomize-multi-region/overlays/us-west1
```{{exec}}

```
kubectl get svc region-service -n us-west1 -o jsonpath='{.spec.clusterIP}'
```{{exec}}

```
curl http://<cluster-ip>/
```

(remplace `<cluster-ip>` par la valeur obtenue juste au-dessus). La
réponse doit confirmer `us-west1`.
