# Scénario Killercoda — Cluster Kubernetes from scratch avec kubeadm

## Contenu

```
kubeadm-from-scratch/
├── index.json              # config du scénario (titre, steps, backend)
├── intro.md                # page d'intro affichée à l'élève
├── intro-background.sh     # script INVISIBLE : prérequis système + containerd
├── step1.md / step1-verify.sh   # installer kubeadm / kubelet / kubectl
├── step2.md / step2-verify.sh   # kubeadm init + config kubectl
├── step3.md / step3-verify.sh   # installer le CNI (Flannel)
├── step4.md / step4-verify.sh   # valider le cluster (déploiement de test)
└── finish.md                # page de fin
```

Pour l'ajouter à ton repo Killercoda, il suffit de placer le dossier
`kubeadm-from-scratch/` à la racine (ou dans un sous-dossier) de ton
repository connecté à Killercoda.

## Choix effectués et pourquoi

- **Environnement Killercoda (`backend.imageid`) : `ubuntu`.**
  C'est le seul environnement générique dont j'ai pu confirmer
  l'existence et le comportement (Ubuntu, mono-VM). Killercoda propose
  aussi des images "prêtes à l'emploi" du type `kubernetes-kubeadm-1node`
  ou `kubernetes-kubeadm-2nodes`, mais celles-ci ont déjà un cluster
  Kubernetes fonctionnel dessus — donc inutilisables pour un exercice
  "from scratch". Je n'ai pas trouvé de documentation confirmant
  l'existence d'un environnement multi-VM "vierge" (sans Kubernetes
  préinstallé) sur Killercoda ; je n'ai donc pas inventé de nœud
  worker. Si ton compte Killercoda dispose d'un tel environnement,
  dis-le-moi et j'adapterai le scénario pour inclure un vrai
  `kubeadm join`.

- **containerd + prérequis système = installés/configurés par un
  script `background` invisible** (`intro-background.sh`), plutôt que
  de compter sur un état préexistant de l'image `ubuntu` que je ne
  pouvais pas garantir avec certitude. Ce script suit la doc officielle
  (modules noyau `overlay`/`br_netfilter`, sysctl, `SystemdCgroup =
  true`). Résultat : l'élève trouve un `containerd` déjà prêt, et sa
  première action visible est bien l'installation de kubeadm/kubelet/
  kubectl, comme demandé.

- **Version Kubernetes : v1.36** (dépôt `pkgs.k8s.io/core:/stable:/v1.36`),
  version courante de la documentation officielle au moment de la
  rédaction (vérifiée en direct sur kubernetes.io).

- **CNI : Flannel**, pour la simplicité du manifeste officiel en une
  seule commande (`kubectl apply -f .../kube-flannel.yml`) et le CIDR
  par défaut `10.244.0.0/16`.

- **Cluster mono-nœud** : le taint control-plane est retiré à l'étape 4
  pour pouvoir y déployer un pod de test et valider le cluster.

## Sources officielles utilisées

- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
- https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
- https://kubernetes.io/docs/setup/production-environment/container-runtimes/
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/
- https://kubernetes.io/blog/2023/08/15/pkgs-k8s-io-introduction/
- https://github.com/flannel-io/flannel (Documentation/kubernetes.md)
- https://killercoda.com/creators (structure de scénario, syntaxe `{{exec}}`)

## Limites connues

- Testé uniquement "sur le papier" : je n'ai pas d'accès direct à
  Killercoda pour exécuter ce scénario de bout en bout. Avant mise en
  prod, lance-le une fois en tant que créateur pour vérifier le
  timing (notamment la durée de `kubeadm init` et du démarrage de
  Flannel face aux timeouts des `verify.sh`).
- Si l'image `ubuntu` de Killercoda change de version d'Ubuntu ou de
  contenu, `intro-background.sh` reste conçu pour être idempotent,
  mais mérite d'être revérifié.
