# Scénario Killercoda — RBAC : permissions de l'utilisateur luke

## Contenu

```
rbac-luke-jedi/
├── index.json
├── intro.md
├── intro-background.sh     # crée le namespace jedi + lien symbolique k -> kubectl
├── step1.md / step1-verify.sh   # Role+RoleBinding : create/delete dans jedi
├── step2.md / step2-verify.sh   # RoleBinding "view" par namespace, hors kube-*
└── finish.md
```

## Choix effectués et pourquoi

- **Backend : `kubernetes-kubeadm-1node`**, le seul backend mono-nœud
  Kubernetes confirmé sur Killercoda (control-plane avec taint retiré,
  prêt à l'emploi). Pas de reset/réinstallation ici, contrairement aux
  autres scénarios : le cluster préinstallé convient tel quel pour un
  exercice RBAC, qui ne touche pas à l'installation de Kubernetes
  lui-même.

- **Alias `k`** : je n'ai trouvé aucune confirmation que ce backend
  fournit `k` comme raccourci de `kubectl` par défaut. Plutôt que de
  supposer que c'est le cas (le scénario aurait échoué en bloc sinon),
  `intro-background.sh` crée un **lien symbolique** `/usr/local/bin/k
  -> kubectl` — contrairement à un alias bash, ça fonctionne
  immédiatement, y compris dans un terminal déjà ouvert, sans dépendre
  du rechargement de `~/.bashrc`.

- **Vérification via `kubectl auth can-i --as=luke`** (demandé
  explicitement) : cette approche évite d'avoir à générer un vrai
  certificat client pour `luke` (CSR, signature par la CA du cluster,
  kubeconfig dédié) — l'usurpation d'identité (`--as`) suffit à tester
  l'autorisation RBAC, indépendamment de l'authentification réelle.
  C'est le mécanisme officiellement prévu pour ce cas d'usage.

- **`--resource=pods,deployments.apps,statefulsets.apps`** (étape 1) :
  le groupe API est précisé explicitement pour `deployments` et
  `statefulsets` (`.apps`). Il existe un bug historique connu de
  `kubectl create role` (issue kubernetes/kubernetes#69488) où
  `deployments` sans groupe explicite pouvait être résolu vers l'ancien
  groupe `extensions` au lieu d'`apps` sur certaines versions.  `pods`
  n'a pas cette ambiguïté (un seul groupe API possible : `core`), donc pas
  besoin de le préciser. Cette précision évite tout risque, quelle que
  soit la version de kubectl utilisée sur ce backend.

- **Étape 2 : boucle sur les namespaces**, plutôt qu'un
  `ClusterRoleBinding`. RBAC n'a pas de mécanisme d'exclusion par motif
  ("tous les namespaces sauf ceux qui commencent par kube-") : un
  `ClusterRoleBinding` s'applique à absolument tous les namespaces sans
  exception, et un `RoleBinding` ne couvre qu'un seul namespace à la
  fois. La seule solution native consiste donc à créer un
  `RoleBinding` par namespace concerné — d'où la boucle shell qui
  liste les namespaces, exclut ceux préfixés `kube-`, et crée un
  binding pour chacun des autres. Limite assumée et mentionnée dans
  `step2.md` : un namespace créé après coup n'hériterait pas
  automatiquement de ce binding.

- **`ClusterRole` `view` réutilisé via un `RoleBinding` namespacé** :
  comportement standard et documenté de Kubernetes (un `ClusterRole`
  peut être lié par un `RoleBinding`, ce qui limite son effet au
  namespace du binding) plutôt que de redéfinir un `Role` personnalisé
  équivalent à `view` dans chaque namespace.

## Sources officielles utilisées

- https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_role/
- https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_rolebinding/
- https://kubernetes.io/docs/reference/kubectl/generated/kubectl_auth/kubectl_auth_can-i/
- https://github.com/kubernetes/kubernetes/issues/69488 (bug historique apiGroups de `kubectl create role`)

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda
  pour dérouler ce scénario de bout en bout.
- Je n'ai pas pu confirmer la présence ou non d'un alias `k`
  préexistant sur `kubernetes-kubeadm-1node` — le lien symbolique
  contourne le problème, mais mérite d'être vérifié en conditions
  réelles (au cas où `k` existerait déjà sous une autre forme en
  conflit).
- La liste exacte des namespaces `kube-*` présents par défaut sur ce
  backend (`kube-system`, `kube-public`, `kube-node-lease`, et
  potentiellement un namespace lié au CNI) n'a pas pu être vérifiée
  précisément ; `step2-verify.sh` interroge dynamiquement les
  namespaces réels du cluster plutôt que de les supposer, donc ce
  point ne devrait pas poser de problème même si la liste diffère de
  ce qui est attendu.
