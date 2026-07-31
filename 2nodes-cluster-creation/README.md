# Scénario Killercoda — Cluster Kubernetes from scratch avec kubeadm

## Contenu

```
kubeadm-from-scratch/
├── index.json              # config du scénario (titre, steps, backend)
├── intro.md                # page d'intro affichée à l'élève
├── intro-background.sh     # script INVISIBLE : reset + désinstallation kubeadm/kubelet/kubectl sur les 2 nœuds
├── step1.md / step1-verify.sh   # installer kubeadm / kubelet / kubectl (sur les 2 nœuds)
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

- **Pas de `sudo`** : les commandes s'exécutent en root par défaut sur
  Killercoda, donc `sudo` a été retiré de toutes les commandes
  (`step1.md`, `step2.md`, `step4.md`).

- **Environnement Killercoda (`backend.imageid`) :
  `kubernetes-kubeadm-2nodes`.** C'est un backend confirmé et
  documenté par Killercoda. Il fournit deux hôtes réels, chacun avec
  son propre onglet de terminal : `controlplane` et `node01`.

  Ce backend arrive avec un cluster Kubernetes déjà installé et déjà
  joint sur les deux nœuds, et les paquets `kubeadm`/`kubelet`/
  `kubectl` déjà présents. Le script `intro-background.sh` remet donc
  les deux nœuds à une base "quasi vierge" :
  1. `kubeadm reset -f` (commande officielle,
     https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-reset/)
     + nettoyage de `/etc/cni/net.d`, de `$HOME/.kube` et des règles
     iptables laissées par kube-proxy (non gérées par `kubeadm reset`
     lui-même, d'après la doc officielle) ;
  2. **désinstallation des paquets `kubeadm`, `kubelet` et
     `kubectl`** (`apt-get purge`), pour que l'étape 1 du scénario
     (les installer) soit réellement nécessaire sur les deux nœuds,
     et pas juste sur `controlplane`.

  `containerd` et les prérequis systèmes (swap, modules noyau,
  sysctl) restent en place : ils sont forcément déjà corrects,
  puisque Kubernetes tournait dessus juste avant.

- **Exécution sur `node01` via SSH.** Le script tourne sur
  `controlplane` et exécute la même séquence à distance sur `node01`
  via `ssh node01 "..."`. Le SSH root sans mot de passe entre les deux
  hôtes fonctionne (confirmé) sur ce backend.

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
  L'étape 1 s'exécute désormais **sur `controlplane` ET sur `node01`**
  (mêmes commandes, à répéter sur les deux onglets), puisque les deux
  nœuds ont été désinstallés par le script de préparation.

- **CNI : Calico**, installé via son **manifeste unique**
  `calico.yaml` (v3.32.1), **sans l'opérateur Tigera** — méthode plus
  basique, toujours documentée officiellement, historiquement la plus
  répandue en production. Le CIDR par défaut du manifeste
  (`192.168.0.0/16`) correspond déjà à celui passé à `kubeadm init` :
  aucune modification du fichier n'est nécessaire. Le DaemonSet
  Calico se déploie automatiquement sur `node01` dès qu'il rejoint le
  cluster, sans étape supplémentaire.

- **Étape 4 : `kubeadm join` sur `node01`.** L'élève récupère la
  commande de jonction (affichée par `kubeadm init`, ou régénérée avec
  `kubeadm token create --print-join-command`) et l'exécute lui-même
  sur l'onglet `node01`. C'est la seule partie du scénario qui n'est
  pas gérée par un script invisible : la commande de jonction est un
  token à usage pédagogique qu'il est plus parlant de faire taper à
  l'élève.

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

- Testé uniquement "sur le papier" : je n'ai pas d'accès direct à
  Killercoda pour exécuter ce scénario de bout en bout. Avant mise en
  prod, vérifie le timing (durée de `kubeadm init`, de la
  désinstallation/réinstallation des paquets, du démarrage des pods
  Calico, du `kubeadm join`) face aux timeouts des `verify.sh`.
- Si le contenu du backend `kubernetes-kubeadm-2nodes` change (version
  de Kubernetes préinstallée, nom des hôtes, etc.), `intro-background.sh`
  et les IP figées (`172.30.1.2`, `172.30.2.2`) mériteraient d'être
  revérifiés.
