# Étape 1 — Environnement et création de la Gateway

## 1. Vérifier que l'environnement est prêt

```
./wait-for-prep.sh
```{{exec}}

## 2. Créer la Gateway

Dans le namespace `imagine-app`, crée une ressource `Gateway` :

- rattachée à la `GatewayClass` **`traefik`**
- avec un listener HTTP, port **`8000`**, hostname `imagine.app`

> ⚠️ Chez Traefik, le port d'un listener `Gateway` doit correspondre
> exactement au port de l'entryPoint Traefik déjà configuré (ici
> l'entryPoint `web`, qui écoute par défaut sur le port conteneur
> `8000` — le port `80` n'existe qu'au niveau du Service Kubernetes,
> pas du process Traefik). Un port qui ne correspond à aucun entryPoint
> rend le listener invalide (`No Listener is valid` / `ListenersNotValid`).
> Ça ne change rien côté élève : on continue d'accéder au service via
> `imagine.app:30080`, seul le port déclaré dans le listener change.

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
    port: 8000
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
