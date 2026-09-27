# Étape 1 — Installer podinfo

Ajoute le dépôt Helm de `podinfo` :

```
helm repo add podinfo https://stefanprodan.github.io/podinfo
```{{exec}}

```
helm repo update
```{{exec}}

Installe le chart `podinfo/podinfo` dans un nouveau namespace de ton
choix (par exemple `podinfo`), avec un message personnalisé :

```
helm install podinfo podinfo/podinfo --namespace podinfo --create-namespace --set ui.message=hello-helm
```{{exec}}

Vérifie :

```
helm list -n podinfo
```{{exec}}

```
kubectl get pods -n podinfo
```{{exec}}
