# Scénario Killercoda — Gateway API & HTTPRoute (Canary)

## Contenu

```
gateway-api-httproute-canary/
├── index.json
├── intro.md
├── intro-background.sh     # CRDs Gateway API + Traefik + NodePort + /etc/hosts + app de démo
├── wait-for-prep.sh         # lancé par l'élève en étape 1 (pattern sentinel)
├── step1.md / step1-verify.sh   # vérif environnement + création Gateway
├── step2.md / step2-verify.sh   # HTTPRoute /api (8080) + /admin (7777)
├── step3.md / step3-verify.sh   # HTTPRoute canary /web (75/25 web-v1/web-v2)
└── finish.md
```

## Changement de technologie par rapport à la demande initiale

La demande initiale décrivait un déploiement `nginx-gateway-fabric`
avec un Service `nginx-gateway` patché directement en NodePort. Vérifié
sur la documentation officielle (docs.nginx.com/nginx-gateway-fabric,
version 2.6.7 à date) : cette architecture ne correspond plus aux
versions actuelles de NGINX Gateway Fabric, qui exigent cert-manager et
provisionnent dynamiquement le data plane (Deployment + Service) à
chaque création d'une `Gateway`, sous un nom dérivé de celle-ci — pas
un Service statique `nginx-gateway` patchable en amont.

**Traefik v3 (Helm)** a été choisi comme remplacement car son
architecture colle presque exactement à la demande initiale : un seul
Deployment et un seul Service statiques (`traefik`), une `GatewayClass`
`traefik` créée automatiquement, aucune dépendance à cert-manager, et
un support natif de la pondération `HTTPRoute.backendRefs[].weight`
(fonctionnalité *core* de la spec Gateway API, donc portable).
`gatewayClass: nginx` devient donc `gatewayClass: traefik`, et l'étape
CRD `nginxgateways.gateway.*` (spécifique à NGINX Gateway Fabric) a été
supprimée : elle n'a pas d'équivalent nécessaire côté Traefik pour cet
usage basique.

## Choix effectués et pourquoi

- **3 étapes** correspondant à la description : (1) vérification de
  l'environnement + création de la `Gateway`, (2) `HTTPRoute` /api +
  /admin, (3) `HTTPRoute` canary /web. La création de la `Gateway` a
  été rattachée à l'étape 1 (plutôt qu'une étape à part), l'énoncé
  numérotant explicitement seulement une "2ème étape" (HTTPRoute
  api/admin) et une "dernière étape" (canary).
- **Namespace applicatif `imagine-app`** : non précisé dans la demande,
  choisi pour rester cohérent avec le hostname `imagine.app`. À
  renommer si tu préfères autre chose.
- **Écart volontaire au thème Star Wars** pour ce scénario : les noms
  (`admin`, `api`, `web-v1`, `web-v2`, `imagine.app`) ont été donnés
  explicitement et littéralement dans la demande.
- **Image `hashicorp/http-echo:1.0`** pour les 4 composants
  applicatifs : image minimale qui renvoie un texte statique
  configurable via `-text=`, ce qui permet de vérifier précisément
  quel backend a répondu (utile pour le test canary). Vérifiée comme
  existante sur Docker Hub, tags disponibles incluant `1.0`.
- **Vérification non déterministe assumée pour le ratio canary**
  (étape 3), même logique que dans `taints-tolerations` : le
  `step3-verify.sh` envoie 100 requêtes (plutôt que les 20 manuelles de
  l'élève) pour limiter le bruit statistique, et vérifie une
  répartition plausible (v1 majoritaire, v2 présent) plutôt qu'un ratio
  exact 75/25.
- **Curl via le hostname `imagine.app`** plutôt que `localhost` ou l'IP
  du nœud en dur, pour rester cohérent avec la résolution `/etc/hosts`
  mise en place et éviter le problème connu de NodePort injoignable
  depuis `localhost` sur le nœud (déjà rencontré sur
  `2nodes-cluster-creation`). Non re-testé spécifiquement sur le
  backend `kubernetes-kubeadm-1node` — à surveiller en priorité.

## Sources officielles utilisées

- https://docs.nginx.com/nginx-gateway-fabric/install/manifests/open-source/
- https://docs.nginx.com/nginx-gateway-fabric/install/deploy-data-plane/
- https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-gateway/
- https://doc.traefik.io/traefik/getting-started/kubernetes/
- https://github.com/traefik/traefik-helm-chart (VALUES.md, values.yaml, templates/gateway.yaml)
- https://hub.docker.com/r/hashicorp/http-echo/tags

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Le port d'un listener `Gateway` doit matcher un entryPoint Traefik
  existant** (confirmé sur `github.com/traefik/traefik`, doc
  `gateway-api.md` : *"Gateway listener ports must match the
  configured EntryPoint ports of the Traefik deployment"*). L'entryPoint
  `web` du chart écoute par défaut sur le port conteneur `8000`, pas
  `80` (`80` n'est que le port du Service Kubernetes). Le listener de
  `step1.md` utilise donc `port: 8000`, pas `80` — sinon la Gateway
  reste `Accepted` (au niveau GatewayClass/contrôleur) mais le listener
  lui-même est rejeté (`No Listener is valid` / `ListenersNotValid`).
  Corrigé après un premier test réel sur Killercoda par Pierrot.
- **`gatewayClass.enabled` indépendant de `gateway.enabled`** dans le
  chart Traefik : la documentation générée (VALUES.md) contient une
  formulation ambiguë sur ce couplage. `intro-background.sh` inclut un
  filet de sécurité (réinstallation avec `gateway.enabled=true` puis
  suppression de la Gateway par défaut) si la GatewayClass n'apparaît
  pas — mais ce chemin de repli n'a pas été testé sur Killercoda.
- **Patch du Service `traefik` par remplacement complet de `spec.ports`**
  (`--type merge`) : suppose qu'il n'y a par défaut que les ports
  `web`/`websecure` exposés (le port dashboard `traefik` et les
  métriques ne le sont pas par défaut selon la doc). Si une version du
  chart expose d'autres ports par défaut, ce patch les supprimerait —
  à vérifier après un premier déploiement réel.
- **`index.json`** : structure best-effort basée sur le schéma standard
  Killercoda ; je n'avais pas un `index.json` existant de ce cursus
  sous les yeux pour calquer exactement vos conventions de champs — à
  aligner si votre format diffère.
- **Testé uniquement "sur le papier"** : comme pour les scénarios
  précédents, pas d'exécution réelle sur Killercoda à ce stade.
- Version des CRDs Gateway API figée à `v1.6.1` (la plus récente
  référencée par la doc Traefik au moment de la rédaction) — à
  ajuster si une version plus récente sort d'ici la mise en prod du
  scénario.
