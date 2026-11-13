# Scénario Killercoda — Contexts : un même manifeste, deux namespaces

## Contenu

```
context-namespace/
├── index.json                   # backend kubernetes-kubeadm-1node, 2 étapes
├── intro.md                     # notion de context (cluster + user + namespace), ce qui est préparé
├── intro-background.sh          # lien k, namespaces hoth/endor, contexts hoth-admin/endor-admin, use-context hoth-admin
├── step1.md / step1-verify.sh   # current-context, get-contexts, k run --dry-run=client > pod.yaml, k apply, pod dans hoth
├── step2.md / step2-verify.sh   # use-context endor-admin, même pod.yaml, pod dans endor, coexistence, flag -n
└── finish.md
```

## Choix effectués

- **Nommage Star Wars** : namespaces `hoth` et `endor`, contexts `hoth-admin` et `endor-admin` (le nom du context n'est pas celui du namespace, pour montrer qu'un context est un triplet cluster / user / namespace), pod `r2-d2`.
- **Préparation** : les deux contexts reprennent le cluster et le user du context courant d'origine, lus avec `k config view --minify -o jsonpath` plutôt qu'écrits en dur. L'élève démarre sur `hoth-admin`. Le script est idempotent.
- **Nom du pod imposé (`r2-d2`)** plutôt qu'un `<nom pod>` à choisir : les scripts de vérification et les commandes cliquables en ont besoin. Même convention que `bb-8` dans le scénario sur les pods.
- **`cd ~` en début d'étape 1** et `ls pod.yaml` en début d'étape 2 : les scripts de vérification lisent `/root/pod.yaml`, donc on ne s'en remet pas au répertoire de départ du terminal.
- **Le manifeste ne doit pas contenir de namespace** : c'est le point pédagogique central. `step1-verify.sh` et `step2-verify.sh` refusent un `pod.yaml` qui contient un champ `namespace`. L'étape 1 prévient l'élève de ne pas passer `-n` à `k run`.
- **`step2-verify.sh` exige le context `endor-admin` courant** : un élève qui ferait `k apply -f pod.yaml -n endor` sans changer de context ne valide pas l'étape. Il vérifie aussi que le pod de `hoth` existe toujours.
- **Ajouts non demandés** : à l'étape 2, un `k get pods -n hoth` depuis `endor-admin` (le flag `-n` s'applique à une commande et ne change pas le context), et dans `finish.md` la commande `k config set-context --current --namespace=<ns>`.

## Tested on paper only — hypothèses à vérifier au premier passage

Je n'ai pas pu exécuter ce scénario contre un cluster, ni compiler un vrai `kubectl` (le proxy Go n'est pas joignable depuis mon environnement). Ce qui a été testé : `bash -n` sur les trois scripts, la validité de `index.json`, et la logique des scripts (préparation, deux scripts de vérification, succès et échecs) avec un **faux `kubectl` que j'ai écrit moi-même** : ces tests ne prouvent donc rien sur le comportement réel de `kubectl`. Ce qui reste à vérifier :

- **Pas de `namespace` dans `pod.yaml`** (point critique) : j'ai lu le code source de `kubectl run` (branche `master`) : en `--dry-run=client`, le namespace n'est écrit dans l'objet que si `EnforceNamespace` est vrai, et `client-go` ne le renvoie vrai que lorsque le namespace vient du flag `-n`, pas du kubeconfig. Deux tickets GitHub vont dans le même sens (avec `-n`, le namespace apparaît dans le YAML). Je n'ai pas exécuté cette commande avec le kubectl 1.35 de Killercoda. Si `pod.yaml` contenait quand même un `namespace`, les deux vérifications échoueraient : c'est le premier test à faire.
- **Contenu de `pod.yaml`** : le texte de l'étape 1 dit qu'on y voit le nom `r2-d2` et un label, sans `namespace`. La structure exacte du YAML généré (label `run: r2-d2`, `creationTimestamp: null`, `status: {}`) est écrite de mémoire.
- **Syntaxes `kubectl config`** : `set-context <nom> --cluster --user --namespace`, `use-context`, `get-contexts` (colonnes `CURRENT`, `NAME`, `CLUSTER`, `AUTHINFO`, `NAMESPACE`, option `-o name`), `config view --minify -o jsonpath`. Écrites de mémoire, jamais exécutées.
- **Kubeconfig de Killercoda** : je suppose que `~/.kube/config` a un context courant à la création de l'environnement. Si ce n'est pas le cas, le script se replie sur le premier cluster et le premier user du fichier.
- **Messages affichés** : `No resources found in endor namespace.` et `pod/r2-d2 created` sont écrits de mémoire.
- **Précédence du namespace du manifeste** : le message d'erreur de la vérification dit qu'un manifeste qui précise son namespace crée le pod dans ce namespace quel que soit le context. C'est le comportement habituel de `kubectl`, mais je ne l'ai pas exécuté.
- **Examen CKA** : l'`intro.md` dit que les énoncés indiquent le context à utiliser ; c'est ce que je sais de l'examen, je ne l'ai pas revérifié dans la documentation actuelle.
- **Timing de la préparation** : le script tourne en arrière-plan. Un élève très rapide pourrait voir `k config get-contexts` sans les deux nouveaux contexts ; `step1-verify.sh` le détecte et demande de patienter.
- **Ordonnancement** : le pod `nginx:alpine` doit pouvoir être planifié sur le nœud unique (pas de taint bloquante sur `controlplane`), comme dans les scénarios précédents sur ce backend. Accès à Docker Hub depuis le nœud supposé.
- **Lien du `finish.md`** : URL de la documentation kubeconfig non vérifiée par un fetch.
