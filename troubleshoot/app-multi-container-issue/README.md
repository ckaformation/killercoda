# Scénario Killercoda — Application multi-conteneurs, conflit de port

## Contenu

```
multicontainer-port-conflict/
├── index.json
├── intro.md
├── intro-background.sh   # namespace + deployment 2 conteneurs (conflit de port)
├── step1.md / step1-verify.sh   # extraction des logs (1 indice + 1 solution)
└── step2.md / step2-verify.sh   # correction du conflit (1 indice + 1 solution)
└── finish.md
```

## Choix effectués et pourquoi

- **Namespace `tatooine`, déploiement `twin-suns`** : thème Star Wars
  — les deux soleils de Tatooine comme image des deux conteneurs en
  concurrence pour la même "place" (le port 80).
- **`httpd` listé en premier dans le pod** (avant `nginx`) pour
  maximiser les chances qu'il gagne la course au `bind()` sur le port
  80, et que ce soit bien `nginx` qui échoue — conforme à l'énoncé.
  Kubernetes ne garantit cependant pas formellement l'ordre de
  démarrage des conteneurs d'un même pod : ce choix influence
  fortement le résultat sans le garantir à 100 %.
- **`containerPort: 80` sur les deux conteneurs** : purement
  documentaire côté Kubernetes (n'a aucun effet d'enforcement réseau)
  — le vrai conflit vient du fait que les configurations par défaut
  de `httpd:2-alpine` et `nginx:1-alpine` écoutent toutes les deux sur
  le port 80 à l'intérieur de l'espace réseau partagé du pod.
- **`kubectl logs --all-containers=true --prefix=true`** en solution
  de l'étape 1 : une seule commande pour récupérer les logs des deux
  conteneurs, avec préfixe indiquant la source de chaque ligne —
  plus simple que deux commandes `kubectl logs -c <conteneur>`
  séparées.
- **`step1-verify.sh` cherche juste les chaînes "nginx" et "httpd"**
  dans le fichier de logs (issues du préfixe), plutôt que des messages
  d'erreur applicatifs précis : plus robuste, ne dépend pas du wording
  exact des logs Apache/nginx.
- **`traefik/whoami:v1.11` avec `--port 8080`** : confirmé sur la
  documentation/les exemples officiels Traefik que l'image accepte un
  argument `--port` pour changer son port d'écoute (par défaut 80).
- **Étape 2 sans méthode imposée dans le texte principal**,
  conformément à la demande ("on ne dira pas comment faire, juste ce
  qu'il doit obtenir") — l'indice mentionne `kubectl edit`, la
  solution détaille la manipulation complète.
- **`wait-for-ready.sh`** (même esprit que le scénario HPA) : attend
  que le conteneur `nginx` ait redémarré au moins une fois, plutôt que
  d'attendre un état "Ready" complet du pod — puisque, par design, le
  pod ne sera jamais pleinement Ready avant l'étape 2.

## Sources utilisées

- Argument `--port` de l'image `traefik/whoami` : exemples officiels
  Traefik (`traefik.io/blog`, `doc.traefik.io`), notamment un exemple
  Docker Compose explicite (`command: - --port=8082`).
- Comportement des conteneurs partageant l'espace réseau d'un pod
  (conflit de bind sur un même port) : connaissance générale
  Kubernetes, non re-vérifiée par recherche dédiée dans cette
  conversation.
- Ports par défaut de `httpd:2-alpine` (80) et `nginx:1-alpine` (80) :
  connaissance générale des images Docker officielles.

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents.
- **Ordre de démarrage des conteneurs** (voir plus haut) : le choix
  de lister `httpd` en premier n'est qu'une influence, pas une
  garantie Kubernetes formelle. Si en pratique c'est `httpd` qui
  échoue au lieu de `nginx`, l'énoncé et les indices resteraient
  globalement valables (juste inversés), mais `step1-verify.sh`
  resterait correct dans tous les cas (il ne présume pas lequel des
  deux a échoué).
- **Format exact du préfixe `kubectl logs --prefix=true`** : je pars
  du principe qu'il inclut le nom du conteneur de façon reconnaissable
  (d'où la vérification par simple `grep`), mais je n'ai pas confirmé
  le format exact pour la version de kubectl utilisée sur ce backend.
