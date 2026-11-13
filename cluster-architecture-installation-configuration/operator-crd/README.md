# Scénario Killercoda — Opérateur Kubernetes et CRD

## Contenu

```
operator-crd-greeting/
├── index.json
├── intro.md
├── intro-background.sh     # namespaces luke/ben/leia, alias k, manifestes de l'opérateur pré-déposés
├── step1.md / step1-verify.sh   # installer l'opérateur + vérifier son RBAC
├── step2.md / step2-verify.sh   # CRD + ressource personnalisée + vérif ConfigMap
└── finish.md
```

## Choix effectués et pourquoi

- **Backend : `kubernetes-kubeadm-1node`.** Un seul nœud suffit ; rien
  dans cet exercice ne justifie la complexité à 2 nœuds des autres
  scénarios (pas de manipulation système bas niveau comme
  `static-pods`).

- **"Opérateur" simplifié en script shell, pas un vrai binaire Go
  (Operator SDK / Kubebuilder).** Impossible de compiler et publier une
  image dans cet environnement Killercoda éphémère (pas de registre, pas
  de pipeline de build). Le choix : un `Deployment` tournant l'image
  `bitnami/kubectl:latest` (déjà utilisée dans `rbac-cronjob-nettoyeur`)
  avec un script shell qui boucle toutes les 10 secondes. C'est un choix
  assumé et explicité dès `intro.md` et rappelé dans `finish.md` : le
  principe (surveiller une ressource personnalisée, réagir en
  conséquence) est fidèle, mais le mécanisme (polling plutôt que
  watch/informer événementiel) est simplifié.

- **Les manifestes de l'opérateur sont pré-déposés sur disque
  (`/root/operator/operator.yaml`) par le script `background`, mais PAS
  appliqués** — c'est le travail de l'élève à l'étape 1
  ("installer l'opérateur", demandé explicitement). Ça évite de lui
  faire saisir à la main, via `vi`, un `Deployment` assez long avec un
  script shell imbriqué (source d'erreurs de frappe élevée pour peu de
  valeur pédagogique), tout en restant réaliste : en pratique, on
  installe un opérateur depuis un bundle YAML fourni, pas en le
  retapant caractère par caractère.

- **Namespace dédié `operators` pour l'opérateur lui-même** (pas
  demandé explicitement, mais choix standard et réaliste — cf. par
  exemple `cert-manager`, `ingress-nginx`, qui tournent dans leur propre
  namespace plutôt que dans ceux qu'ils gèrent). Créé par le manifeste
  de l'opérateur lui-même (`kind: Namespace` en tête du fichier), pas
  par le script `background`, pour que `kubectl apply -f
  operator.yaml` soit auto-suffisant.

- **RBAC scopé à `luke`/`ben`/`leia` via un `ClusterRole` + 3
  `RoleBinding`** (un par namespace), exactement la même technique que
  `rbac-luke-jedi` — cohérence délibérée avec le reste du cursus. Droits
  accordés : `get`/`list`/`watch` sur `greetings` (la future CRD),
  `get`/`list`/`create` sur `configmaps`.

- **CRD `greetings.training.example.com`, `apiVersion:
  apiextensions.k8s.io/v1`, avec schéma OpenAPI v3 obligatoire**
  (`spec.versions[].schema.openAPIV3Schema`) : contrairement à l'ancien
  `v1beta1` (retiré depuis Kubernetes 1.22), la version `v1` de l'API
  CRD exige un schéma structurel — omis, la CRD serait rejetée par
  l'API server. Un seul champ dans le schéma (`spec.message: string`),
  conformément à la demande d'une CRD "assez simpliste".

- **Message du Greeting d'exemple générique** ("Bienvenue dans le
  namespace luke"), volontairement neutre plutôt qu'une réplique de
  film (malgré le thème `luke`/`ben`/`leia`), pour ne pas reproduire de
  dialogue soumis au droit d'auteur.

- **Nom de ConfigMap dérivé du nom de la ressource** (`<nom-du-greeting>-greeting`)
  plutôt qu'un champ dédié dans le spec : garde la CRD minimale
  (un seul champ), cohérent avec "assez simpliste".

- **`vi` pour la CRD et la ressource `Greeting`** (courtes, faible
  risque), **fichier pré-généré pour le `Deployment` de l'opérateur**
  (long, RBAC scopé, un caractère mal placé casserait plus qu'un pod
  applicatif) — même logique de dosage du risque que dans
  `static-pods` (`vi` pour le manifeste applicatif isolé, `sed`/fichiers
  contrôlés pour ce qui touche à des mécanismes plus larges).

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
- https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/
- https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/ (réutilisation de `rbac-luke-jedi`)

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le temps de pull de l'image `bitnami/kubectl:latest` (déjà signalé
  dans `rbac-cronjob-nettoyeur`) pourrait retarder le démarrage de
  l'opérateur à l'étape 1 — le `kubectl wait --timeout=60s` dans
  `step1-verify.sh` pourrait s'avérer un peu juste si le pull est lent.
- Le polling toutes les 10 secondes introduit un délai incompressible
  entre la création du `Greeting` et l'apparition de la `ConfigMap` —
  `step2-verify.sh` prévoit une boucle d'attente de 40 secondes pour
  l'absorber, mais un environnement particulièrement lent pourrait
  nécessiter un ajustement.
- Le YAML du `Deployment` de l'opérateur a été validé syntaxiquement
  (parsing YAML multi-documents réussi), mais je n'ai pas pu tester son
  exécution réelle sur un cluster — à vérifier en priorité au premier
  test.
