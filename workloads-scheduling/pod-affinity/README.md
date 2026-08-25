# Scénario Killercoda — Pod Affinity

## Contenu

```
pod-affinity/
├── index.json
├── intro.md
├── intro-background.sh     # taint control-plane retiré, pods yoda/luke + YAML sur disque
├── step1.md / step1-verify.sh   # tentative d'edit (échec), édition du fichier, delete+recreate
├── step2.md / step2-verify.sh   # delete des 2 pods, nodeName de yoda changé, luke suit
└── finish.md
```

## Choix effectués et pourquoi

- **Immuabilité de `spec.affinity` sur un pod déjà créé, rendue explicite
  et vécue par l'élève** (étape 1) : la demande décrit "l'élève doit
  modifier un autre pod" sans préciser la mécanique exacte. Techniquement,
  un `kubectl edit` direct sur un pod vivant pour y ajouter
  `spec.affinity` est rejeté par l'API server (seuls quelques champs
  précis — image des conteneurs, tolerations en ajout, quelques autres —
  restent modifiables après création). Plutôt que de contourner
  silencieusement ce point en ne montrant que la bonne méthode, l'étape 1
  fait tenter l'edit direct à l'élève, montre l'échec, puis explique
  pourquoi avant de passer à la méthode qui fonctionne (éditer le
  fichier, `delete` + `apply`). Choix pédagogique assumé : c'est aussi
  l'occasion de comprendre pourquoi des contrôleurs comme `Deployment`
  existent.

- **Les deux pods (`yoda` et `luke`) ont leurs définitions YAML déposées
  sur disque dès le script `background`**, pas seulement `yoda`
  (explicitement demandé) : `luke` a lui aussi besoin d'être
  supprimé/recréé à partir d'un fichier à l'étape 1, pour la raison
  d'immuabilité ci-dessus — impossible de le faire proprement sans que
  son YAML soit disponible.

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
