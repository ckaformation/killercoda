# Étape 1 — Environnement et création de la Gateway

## 1. Vérifier que l'environnement est prêt

```
./wait-for-prep.sh
```{{exec}}

## 2. Créer la Gateway

Dans le namespace `imagine-app`, crée une ressource `Gateway` :

- rattachée à la `GatewayClass` **`traefik`**
- avec un listener HTTP, port `80`, hostname `imagine.app`

Exemple :

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: imagine-gateway
  namespace: imagine-app
spec:
  gatewayClassName: traefik
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    hostname: imagine.app
    allowedRoutes:
      namespaces:
        from: Same
```

Applique-la, puis vérifie son statut :

```
kubectl get gateway -n imagine-app
kubectl describe gateway -n imagine-app
```{{exec}}

Tu dois voir les conditions `Accepted` et `Programmed` à `True`.
