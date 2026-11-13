# Bravo !

Tu as manipulé les objets centraux de la Gateway API :

- `Gateway` : point d'entrée du trafic, rattaché à une `GatewayClass`
- `HTTPRoute` : règles de routage HTTP, y compris le routage par
  chemin (`PathPrefix`) et la répartition pondérée du trafic
  (`backendRefs[].weight`) — le mécanisme de base derrière un
  déploiement **canary**.

## Pour aller plus loin

- Fais varier les poids (ex. 50/50, 90/10) et observe l'effet sur la
  répartition.
- Ajoute un listener HTTPS avec un certificat TLS.
- Explore les conditions détaillées d'une `HTTPRoute` avec
  `kubectl describe httproute -n imagine-app`.
