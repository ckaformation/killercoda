# Étape 2 — HTTPRoute /api et /admin

Crée une `HTTPRoute` dans le namespace `imagine-app`, rattachée à la
Gateway créée à l'étape précédente, qui expose :

- `/api` → service `api`, port `8080`
- `/admin` → service `admin`, port `7777`

Exemple :

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: imagine-routes
  namespace: imagine-app
spec:
  parentRefs:
  - name: imagine-gateway
  hostnames:
  - imagine.app
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
    backendRefs:
    - name: api
      port: 8080
  - matches:
    - path:
        type: PathPrefix
        value: /admin
    backendRefs:
    - name: admin
      port: 7777
```

Applique-la, puis teste :

```
curl http://imagine.app:30080/api
curl http://imagine.app:30080/admin
```{{exec}}
