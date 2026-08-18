# Scénario Killercoda — Upgrade d'un cluster kubeadm (v1.35 → v1.36)

## Contenu

```
kubeadm-cluster-upgrade/
├── index.json
├── intro.md
├── intro-background.sh     # INVISIBLE : monte un cluster v1.35.x complet et fonctionnel
├── step1.md / step1-verify.sh   # explorer l'état actuel
├── step2.md / step2-verify.sh   # upgrade kubeadm + kubeadm upgrade apply (controlplane)
├── step3.md / step3-verify.sh   # drain + kubelet/kubectl + uncordon (controlplane)
├── step4.md / step4-verify.sh   # upgrade kubeadm + kubeadm upgrade node (node01)
├── step5.md / step5-verify.sh   # drain + kubelet/kubectl + uncordon (node01) + vérif finale
└── finish.md
```

Place ce dossier dans le même groupe que `2nodes-cluster-creation`
(`cluster-architecture-installation-configuration/`) pour qu'il apparaisse
dans le même "course" Killercoda.

## Différence clé avec `2nodes-cluster-creation`

Ce scénario réutilise le même backend (`kubernetes-kubeadm-2nodes`) et une
bonne partie de la même logique de préparation (reset, réinstallation des
paquets, `kubeadm init`, Calico, `kubeadm join`), mais **le cluster n'est
pas détruit** : il est laissé fonctionnel, en v1.35.x, pour que l'exercice
de l'élève soit la mise à niveau elle-même — pas la création du cluster.

## Choix effectués et pourquoi

- **Version de départ : v1.35.x. Version cible : v1.36.x.** Choix
  directement confirmé par la documentation officielle "Upgrading kubeadm
  clusters", consultée en direct au moment de la rédaction : elle décrit
  explicitement la transition "from version 1.35.x to version 1.36.x"
  comme la procédure courante.

- **Aucune version de patch n'est codée en dur.** Le script de préparation
  détermine la version installée dynamiquement (`kubeadm version -o
  short`) plutôt que d'écrire un numéro de patch que je ne peux pas
  vérifier avec certitude. Les étapes visibles font pareil, via
  `apt-cache madison` — c'est d'ailleurs exactement la méthode recommandée
  par la doc officielle ("find the latest patch release using the OS
  package manager").

- **Ordre des opérations pour le control-plane** (étapes 2 et 3) : upgrade
  du paquet `kubeadm` → `kubeadm upgrade plan` → `kubeadm upgrade apply`
  → drain → upgrade `kubelet`/`kubectl` → redémarrage de kubelet →
  uncordon. Cet ordre précis (upgrade apply AVANT le drain) est celui de
  la doc officielle actuelle, vérifié via la page live.

- **Ordre des opérations pour le worker** (étapes 4 et 5) : upgrade du
  paquet `kubeadm` → `kubeadm upgrade node` → drain (déclenché depuis
  `controlplane`) → upgrade `kubelet`/`kubectl` → redémarrage → uncordon
  (déclenché depuis `controlplane`). Confirmé par la page officielle
  "Upgrading Linux nodes".

- **`kubeadm upgrade node` (et non `apply`) sur le worker** : `apply`
  n'est utilisable que sur un nœud control-plane ; c'est une source
  d'erreur fréquente documentée (y compris sur le forum officiel
  Kubernetes), d'où l'insistance sur ce point dans `step4.md`.

- **Calico non mis à niveau** : la mise à niveau du CNI est mentionnée
  comme hors périmètre (aussi bien dans `intro.md` que `finish.md`),
  conformément à la demande initiale ("upgrade kubernetes et de ses
  dépendances, kubectl par exemple").

## Sources officielles utilisées

- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/ (page live, confirmée traiter 1.35→1.36)
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/upgrading-linux-nodes/
- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/change-package-repository/
- https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-version/ (flag `-o short`)

## Limites connues

- Comme pour `2nodes-cluster-creation`, testé uniquement "sur le papier" :
  je n'ai pas d'accès direct à Killercoda. À tester en priorité :
  - le temps total du script `background` (il fait bien plus de travail
    que celui de `2nodes-cluster-creation` : reset + réinstall sur 2
    nœuds EN PLUS de `kubeadm init` + Calico + `kubeadm join` + attentes
    `Ready`) — le timeout de `wait-for-prep.sh` a été porté à 240s en
    conséquence, à ajuster si besoin ;
  - que `apt-cache madison` renvoie bien des résultats exploitables une
    fois le dépôt v1.36 activé (dépend de la disponibilité réelle de
    paquets v1.36.x sur `pkgs.k8s.io` au moment du test) ;
  - le comportement de `kubeadm upgrade apply -y` (flag présumé correct
    d'après plusieurs sources concordantes, mais pas vérifié en conditions
    réelles).
