# Scénario Killercoda — Opérateur Kubernetes : StatefulSet, CRD, évolution RBAC

## Contenu

```
operator-namespace-provisioner/
├── index.json
├── intro.md
├── intro-background.sh     # namespace operators, SA+ClusterRole (sans patch)+ClusterRoleBinding, StatefulSet pré-déposé
├── step1.md / step1-verify.sh   # déployer le StatefulSet
├── step2.md / step2-verify.sh   # déployer la CRD
├── step3.md / step3-verify.sh   # déployer la CR, observer la création des 3 namespaces
├── step4.md / step4-verify.sh   # ajouter la labellisation + corriger le ClusterRole
└── finish.md
```

## Choix effectués et pourquoi

- **Suite de `operator-crd-greeting`**, dans un nouveau dossier
  indépendant (pas une modification du scénario précédent) : mécaniques
  trop différentes (StatefulSet plutôt que Deployment, RBAC qui évolue
  en cours de scénario) pour cohabiter proprement dans le même
  scénario.

- **Opérateur en `StatefulSet`, demandé explicitement.** Inhabituel pour
  un opérateur (les vrais utilisent quasi systématiquement un
  `Deployment`, un opérateur étant normalement sans état) — assumé tel
  quel. J'ai accompagné le `StatefulSet` d'un `Service` headless
  (`clusterIP: None`), requis par la spec Kubernetes pour tout
  `StatefulSet` (`serviceName` est un champ obligatoire), même si notre
  opérateur n'exploite pas vraiment l'identité réseau stable que ça lui
  procure.

- **CRD `NamespaceSet`, `scope: Cluster`** (pas `Namespaced`, à la
  différence de la CRD `Greeting` du scénario précédent) : elle pilote
  la création d'objets `Namespace`, eux-mêmes cluster-scoped — un choix
  de `scope: Namespaced` aurait été fonctionnellement trompeur (dans
  quel namespace la ressource devrait-elle vivre ?). Conséquence directe
  et voulue : le RBAC de l'opérateur ne peut être qu'un `ClusterRole` +
  `ClusterRoleBinding` (pas de `RoleBinding` possible sur une ressource
  cluster-scoped) — contrairement à `operator-crd-greeting`, qui utilisait
  des `RoleBinding` namespacés.

- **ClusterRole créé sans le verbe `patch` dès le script `background`**,
  demandé explicitement : `get`/`list`/`create` sur `namespaces`
  seulement. L'ajout du verbe `patch` à l'étape 4 est donc une
  correction réelle d'un manque réel, pas une simulation.

- **StatefulSet pré-déposé sur disque** (`/root/operator/statefulset.yaml`),
  **CRD et CR écrites à la main via `vi`** : même logique de dosage du
  risque que dans les scénarios précédents (`operator-crd-greeting`,
  `static-pods`) — long manifeste avec script imbriqué d'un côté,
  objets courts de l'autre.

- **Commentaire `# TODO` dans le script initial de l'opérateur**, à
  l'endroit précis où ajouter la commande de labellisation : sans ce
  repère, retrouver le bon endroit dans un script shell imbriqué dans du
  YAML, via `kubectl edit` (donc dans `vi`), serait source d'erreurs
  sans grande valeur pédagogique ajoutée.

- **`kubectl label ... --overwrite` plutôt que `kubectl patch`
  directement** pour la nouvelle fonctionnalité : plus lisible pour
  l'élève, tout en illustrant le même point RBAC (`kubectl label`
  envoie une requête PATCH en coulisses, donc exige le verbe `patch` —
  pas un verbe "label" séparé, qui n'existe pas dans le modèle RBAC de
  Kubernetes).

- **La boucle de l'opérateur retente le label à chaque cycle, y compris
  pour des namespaces déjà créés lors d'un cycle précédent** (pas de
  branchement conditionnel autour de la ligne ajoutée par l'élève) :
  ça correspond au principe de réconciliation continue d'un opérateur
  (converger vers l'état désiré à chaque cycle, pas seulement à la
  création), et ça évite à l'élève d'avoir à recréer la ressource
  `NamespaceSet` après correction du RBAC — le prochain cycle suffit.

- **`kubectl edit clusterrole` pour corriger le RBAC** (plutôt qu'un
  `kubectl patch` scripté) : cohérent avec `rbac-cronjob-nettoyeur`, qui
  utilise la même approche interactive pour ce type de correction RBAC
  ponctuelle.

## Sources officielles utilisées

- https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/
- https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/ (nécessité du Service headless)

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le nom du pod de l'opérateur est supposé stable et prévisible
  (`namespace-operator-0`, convention standard de nommage des pods de
  StatefulSet à 1 replica) — cohérent avec le comportement documenté des
  StatefulSets, mais pas vérifié en conditions réelles sur ce backend.
- Le temps de pull de `bitnami/kubectl:latest` (déjà signalé dans les
  scénarios précédents utilisant cette image) pourrait retarder le
  démarrage initial du pod à l'étape 1, et son redémarrage après l'édit
  à l'étape 4.
- `kubectl rollout status statefulset/...` est utilisé pour attendre le
  redémarrage du pod après édition — comportement standard documenté
  des StatefulSets, mais pas testé en conditions réelles ici.
