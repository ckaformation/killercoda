# Gateway API & HTTPRoute — Canary avec Traefik

Dans ce scénario, tu vas manipuler directement les objets de la **Gateway
API** Kubernetes (`Gateway`, `HTTPRoute`) et mettre en place un
**déploiement canary** en répartissant le trafic entre deux versions
d'une même application.

## Ce qui est déjà en place

Pendant que tu lis cette page, l'environnement se prépare en arrière-plan :

- Les CRDs de la Gateway API (canal *standard*)
- Traefik, installé comme contrôleur Gateway API (`GatewayClass: traefik`)
- Le Service `traefik` exposé en `NodePort` (HTTP: `30080`, HTTPS: `30443`)
- L'entrée `imagine.app` dans `/etc/hosts`, pointant vers l'IP du nœud
- Un namespace applicatif `imagine-app` contenant 4 déploiements de
  démonstration (chacun avec son Service) :
  - `admin` (port `7777`)
  - `api` (port `8080`)
  - `web-v1` et `web-v2` (port `80`), qui répondent respectivement
    `Welcome to the website - v1` et `Welcome to the website - v2`

## Ce que tu vas faire

1. Vérifier que l'environnement est prêt, puis créer une `Gateway`
   rattachée à la `GatewayClass` `traefik`.
2. Créer une `HTTPRoute` exposant `/api` et `/admin`.
3. Créer une `HTTPRoute` canary répartissant `/web` à 75 % vers
   `web-v1` et 25 % vers `web-v2`.

C'est parti !
