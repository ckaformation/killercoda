# Étape 3 — HTTPRoute canary sur /web

Crée une nouvelle `HTTPRoute` dans `imagine-app`, rattachée à la même
Gateway, qui route `/web` en répartissant le trafic :

- 75 % vers `web-v1`
- 25 % vers `web-v2`

Exemple :

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: imagine-web-canary
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
        value: /web
    backendRefs:
    - name: web-v1
      port: 80
      weight: 75
    - name: web-v2
      port: 80
      weight: 25
```

Applique-la, puis observe la répartition avec une boucle de 20 requêtes :

```
for i in $(seq 1 20); do curl -s http://imagine.app:30080/web; echo; done
```{{exec}}

Tu dois voir apparaître un mélange de réponses
`Welcome to the website - v1` (majoritaire) et
`Welcome to the website - v2`.

> Sur seulement 20 requêtes, le ratio observé peut s'écarter de 75/25 —
> c'est un comportement statistique du répartiteur, pas une erreur.
