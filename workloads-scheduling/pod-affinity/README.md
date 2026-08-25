# Scénario Killercoda — Pod Affinity

## Contenu

```
pod-affinity/
├── index.json
├── intro.md
├── intro-background.sh     # taint control-plane retiré, seul yoda tourne, luke.yaml déposé (pas appliqué)
├── step1.md / step1-verify.sh   # complétion de luke.yaml (affinity) + premier lancement
├── step2.md / step2-verify.sh   # tentative d'edit sur yoda (échec), delete+recreate, luke suit
└── finish.md
```

## Choix effectués et pourquoi

- **`luke` n'existe pas au démarrage : c'est l'élève qui le lance, à
  l'étape 1, après avoir complété son fichier avec la pod affinity.**
  Demandé explicitement (correctif apporté après une première version
  où les deux pods étaient déjà en cours d'exécution dès le départ).
  Conséquence : la démonstration de l'immuabilité de `spec.affinity`
  (tenter un `kubectl edit` et observer l'échec) n'a plus de sens à
  l'étape 1, puisqu'il n'y a rien à éditer sur un pod qui n'existe pas
  encore — je l'ai déplacée à l'étape 2, où elle s'applique tout aussi
  bien à `spec.nodeName` (également immuable), qu'il faut de toute
  façon modifier à ce moment-là.

- **Les deux fichiers YAML (`yoda.yaml`, `luke.yaml`) sont malgré tout
  déposés sur disque dès le script `background`** : `yoda.yaml` parce
  que le pod correspondant tourne déjà (accessible pour modification
  future, demandé explicitement pour ce pod) ; `luke.yaml` parce que
  l'élève doit le compléter avant de le lancer pour la première fois.

- **Retrait explicite du taint control-plane par défaut**, comme dans
  `node-selector-scheduling` et `taints-tolerations`, mais pour une
  raison plus subtile ici : `yoda` (placé via `nodeName`) n'est pas
  concerné, un `nodeName` explicite **court-circuite entièrement le
  scheduler**, y compris les vérifications de taint. `luke`, en
  revanche, passe par le scheduler normal (son placement dépend de son
  affinity, pas d'un `nodeName` figé) — à l'étape 2, si `controlplane`
  restait taintée, `luke` resterait bloqué en attente malgré une
  affinity satisfaite, puisqu'un taint intolérable reste bloquant
  indépendamment de toute autre contrainte de placement satisfaite.

- **`topologyKey: kubernetes.io/hostname`** : label présent nativement
  sur tout nœud Kubernetes, valeur = le nom du nœud — garantit que
  "même valeur de topologyKey" équivaut exactement à "même nœud".

- **Ordre explicite de recréation à l'étape 2 (`yoda` avant `luke`)** :
  avec `requiredDuringSchedulingIgnoredDuringExecution`, le pod cible de
  l'affinité doit déjà être présent (schedulé) pour que le pod affine
  puisse être placé sans délai. Appliquer `luke` avant `yoda` l'aurait
  laissé en `Pending` jusqu'à l'apparition de `yoda`.

- **Noms à thème Star Wars** (`yoda` : figure stable, associée à un lieu
  précis dans l'histoire — Dagobah — cohérent avec son placement
  explicite par `nodeName` ; `luke` : cherche et suit Yoda pour
  s'entraîner, cohérent avec la pod affinity qui le fait "suivre" yoda),
  conformément à la préférence indiquée pour ce cursus.

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity
- https://kubernetes.io/docs/concepts/workloads/pods/#pod-update-and-replacement (immuabilité de la spec d'un Pod)

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le message d'erreur exact renvoyé par l'API server lors de la
  tentative d'edit (étape 1, point 2) n'est pas cité mot pour mot dans
  `step1.md` — seulement décrit ("Forbidden: pod updates may not change
  fields other than..."), le texte précis pouvant varier légèrement
  selon la version de Kubernetes. Le comportement global (rejet de la
  modification) est en revanche une garantie API stable.
