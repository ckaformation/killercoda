# Scénario Killercoda — Cluster Kubernetes from scratch avec kubeadm

## Contenu

```
kubeadm-from-scratch/
├── index.json              # config du scénario (titre, steps, backend)
├── intro.md                # page d'intro affichée à l'élève
├── intro-background.sh     # script INVISIBLE : reset kubeadm des 2 nœuds
├── step1.md / step1-verify.sh   # installer kubeadm / kubelet / kubectl
├── step2.md / step2-verify.sh   # kubeadm init + config kubectl
├── step3.md / step3-verify.sh   # installer le CNI (Calico)
├── step4.md / step4-verify.sh   # rattacher node01 (kubeadm join)
├── step5.md / step5-verify.sh   # valider le cluster (déploiement de test)
└── finish.md                # page de fin
```

Pour l'ajouter à ton repo Killercoda, il suffit de placer le dossier
`kubeadm-from-scratch/` à la racine (ou dans un sous-dossier) de ton
repository connecté à Killercoda.

## Choix effectués et pourquoi

- **Environnement Killercoda (`backend.imageid`) :
  `kubernetes-kubeadm-2nodes`.** C'est un backend **confirmé et
  documenté** par Killercoda (contrairement à un hypothétique
  environnement "2 VM Ubuntu vierges" que je n'ai jamais réussi à
  vérifier malgré plusieurs recherches). Il fournit deux hôtes réels,
  chacun avec son propre onglet de terminal : `controlplane` et
  `node01`.

  ⚠️ Ce backend arrive avec un cluster Kubernetes **déjà installé et
  déjà joint** sur les deux nœuds — ce n'est donc pas vierge par
  défaut. Le script `intro-background.sh` s'en sert comme d'un
  raccourci : il utilise `kubeadm reset` (commande officielle,
  https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-reset/)
  pour supprimer l'état créé par kubeadm sur les deux nœuds, tout en
  conservant `containerd`, les paquets `kubeadm`/`kubelet`/`kubectl`
  et les prérequis systèmes — qui sont forcément déjà corrects,
  puisque Kubernetes tournait dessus juste avant.

- **Point d'incertitude assumé, accepté par toi** : le script
  `intro-background.sh` ne s'exécute (à ma connaissance, confirmée)
  que sur l'hôte `controlplane`. Pour réinitialiser `node01` aussi, le
  script tente une connexion **SSH** (`node01`, puis repli sur l'IP
  fixe `172.30.2.2`) pour y lancer la même commande `kubeadm reset -f`.
  Je n'ai **pas de confirmation officielle** que le SSH root sans mot
  de passe est préconfiguré entre les deux hôtes sur ce backend — un
  témoignage d'utilisateur mentionne "ssh to node01" sans plus de
  détail. Si le SSH échoue, le script le signale dans ses logs (visibles
  dans Creator Debug) sans bloquer le scénario, et une remarque a été
  ajoutée dans `step1.md` pour que l'élève relance `sudo kubeadm reset -f`
  lui-même sur `node01` en cas de souci au moment du `kubeadm join`
  (étape 4).

- **`kubeadm init`** (étape 2, sur `controlplane`) utilise les options
  suivantes (demandées explicitement) :
  - `--pod-network-cidr=192.168.0.0/16`
  - `--apiserver-advertise-address=172.30.1.2` (IP interne fixe de
    `controlplane` sur Killercoda)
  - `--kubernetes-version=v1.36.2`
  - `--ignore-preflight-errors=NumCPU` (kubeadm exige ≥ 2 CPU par
    défaut)
  - `--ignore-preflight-errors=Mem` (kubeadm exige ≥ 1700 Mo de RAM
    par défaut)

  Le détail de chaque option est expliqué dans `step2.md`.

- **Version Kubernetes pour l'installation des paquets (étape 1) :
  dépôt `pkgs.k8s.io/core:/stable:/v1.36`**, version courante de la
  documentation officielle au moment de la rédaction (vérifiée en
  direct sur kubernetes.io). Le `kubeadm init` de l'étape 2 épingle
  ensuite explicitement le patch `v1.36.2` via `--kubernetes-version`.
  `node01` dispose déjà des mêmes paquets (même image de base), donc
  l'étape 1 ne s'exécute que sur `controlplane`.

- **CNI : Calico**, installé via son **manifeste unique**
  `calico.yaml` (v3.32.1), **sans l'opérateur Tigera** — méthode plus
  basique, toujours documentée officiellement, historiquement la plus
  répandue en production. Le CIDR par défaut du manifeste
  (`192.168.0.0/16`) correspond déjà à celui passé à `kubeadm init` :
  aucune modification du fichier n'est nécessaire. Le DaemonSet
  Calico se déploie automatiquement sur `node01` dès qu'il rejoint le
  cluster, sans étape supplémentaire.

- **Étape 4 (nouvelle) : `kubeadm join` sur `node01`.** L'élève
  récupère la commande de jonction (affichée par `kubeadm init`, ou
  régénérée avec `kubeadm token create --print-join-command`) et
  l'exécute lui-même sur l'onglet `node01`. C'est la seule partie du
  scénario qui n'est pas gérée par un script invisible : la commande
  de jonction est un token à usage pédagogique qu'il est plus
  parlant de faire taper à l'élève.

- **Étape 5 : validation du cluster.** Le retrait du taint
  control-plane est conservé comme "filet de sécurité" (au cas où
  `node01` n'aurait pas pu rejoindre le cluster), mais le pod de test
  devrait normalement se retrouver planifié sur `node01`.

## Sources officielles utilisées

- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
- https://kubernetes.io/docs/setup/production-environment/container-runtimes/
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/
- https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-reset/ (commande et limites de `kubeadm reset`)
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/adding-linux-nodes/
- https://kubernetes.io/blog/2023/08/15/pkgs-k8s-io-introduction/
- https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises (installation par manifeste, sans opérateur)
- https://github.com/kubernetes/kubernetes/pull/93275 (seuil du preflight check "Mem" = 1700 Mo)
- https://killercoda.com/creators (structure de scénario, syntaxe `{{exec}}`, backends existants)

## Limites connues

- **Le point le plus fragile du scénario est le reset SSH de
  `node01`.** Je n'ai pas pu le tester en conditions réelles. À la
  première exécution en tant que créateur, vérifie dans les logs de
  `intro-background.sh` (Creator Debug) si le reset de `node01` a
  réussi. S'il échoue systématiquement, la remarque de secours dans
  `step1.md` prend le relais, mais le scénario perd un peu de son
  côté "tout est prêt".
- Testé uniquement "sur le papier" par ailleurs : je n'ai pas d'accès
  direct à Killercoda pour exécuter ce scénario de bout en bout.
  Avant mise en prod, vérifie aussi le timing (durée de `kubeadm
  init`, du démarrage des pods Calico, du `kubeadm join`) face aux
  timeouts des `verify.sh`.
- Si le contenu du backend `kubernetes-kubeadm-2nodes` change (version
  de Kubernetes préinstallée, nom des hôtes, etc.), `intro-background.sh`
  et les IP figées (`172.30.1.2`, `172.30.2.2`) mériteraient d'être
  revérifiés.
