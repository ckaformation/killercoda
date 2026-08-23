# Scénario Killercoda — Static Pods : manifests, kubelet et crictl

## Contenu

```
static-pods/
├── index.json
├── intro.md
├── intro-background.sh     # alias k + crictl, sur controlplane ET node01
├── step1.md / step1-verify.sh   # créer static-web (nginx) sur node01 + vérif kubectl + crictl
├── step2.md / step2-verify.sh   # changer staticPodPath de node01, en toute sécurité
└── finish.md
```

## Choix effectués et pourquoi

- **Backend : `kubernetes-kubeadm-2nodes`** (`controlplane` + `node01`),
  changé depuis une version précédente de ce scénario qui utilisait
  `kubernetes-kubeadm-1node`. Choix demandé explicitement : toute la
  manipulation de la configuration du kubelet (étape 2) se fait sur
  `node01`, un nœud worker sans aucun composant du control-plane —
  éliminant le risque de casser `kube-apiserver`/`etcd`/`kube-scheduler`/
  `kube-controller-manager` en cas d'erreur, contrairement à une
  manipulation équivalente sur `controlplane`.

- **`node01` a un `staticPodPath` vide (ou presque) par défaut.**
  Contrairement à `controlplane`, un nœud worker n'héberge aucun
  composant du control-plane sous forme de static pod (kube-proxy, par
  exemple, est un DaemonSet standard, pas un static pod) — donc
  `/etc/kubernetes/manifests` n'y contient a priori que ce que l'élève y
  ajoute lui-même. Ça simplifie la mécanique de relocalisation de
  l'étape 2 (il n'y a qu'un seul fichier à copier), tout en gardant
  intact l'avertissement général sur le risque, applicable à *tout*
  nœud (y compris control-plane) dans un contexte réel — `step2.md`
  explicite cette distinction.

- **Manifeste `static-web` : repris quasi à l'identique de l'exemple
  officiel** ("Create static Pods",
  https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/),
  qui utilise justement `nginx` comme image simple.

- **Préparation (alias `k`, `crictl`) sur les deux nœuds**, en parallèle
  (`bash -c` en local pour `controlplane`, SSH pour `node01`, `wait` sur
  les deux) — même pattern que `2nodes-cluster-creation` et
  `kubeadm-cluster-upgrade`.

- **Découpage des vérifications entre les deux nœuds** : `kubectl` (pod
  miroir, statut des nœuds, pods du control-plane) s'exécute toujours
  depuis `controlplane`, où il est configuré ; `crictl` et la lecture de
  `/var/lib/kubelet/config.yaml` s'exécutent sur `node01`, via SSH
  depuis les `verify.sh` (SSH sans mot de passe entre les deux nœuds,
  confirmé fonctionnel sur ce backend dans les scénarios précédents).

- **`step2-verify.sh` vérifie aussi les 4 pods du control-plane sur
  `controlplane`** (label `tier=control-plane`, comme dans
  `kubeadm-cluster-upgrade`) : confirme explicitement qu'ils n'ont pas
  été affectés par la manipulation sur `node01`, pas seulement que
  `static-web` a survécu.

- **`cp` plutôt que `mv`, `sed` plutôt que `vi` pour la config kubelet**,
  **`vi` conservé pour le manifeste applicatif** : mêmes raisons que
  dans la version précédente de ce scénario (filet de rattrapage,
  fiabilité d'une commande déterministe sur un fichier dont dépend le
  démarrage du kubelet, réalisme "type CKA" pour un pod applicatif isolé
  et sans risque).

## Sources officielles utilisées

- https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/ (manifeste `static-web`, avertissement sur les fichiers de sauvegarde dans le staticPodPath)
- https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/
- https://github.com/kubernetes-sigs/cri-tools (releases crictl)

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Je n'ai pas de confirmation directe que `/etc/kubernetes/manifests`
  est bien vide par défaut sur `node01` de ce backend précis — c'est
  l'attente standard pour un nœud worker kubeadm, mais `step1.md`
  reste correct même si ce n'est pas le cas (le `ls` affiché sert
  justement à ce que l'élève constate l'état réel, pas un état supposé).
- La présence ou non de `crictl` par défaut n'a pas pu être confirmée ;
  l'installation défensive couvre ce cas, mais la version choisie
  (`v1.33.0`) est arbitraire — à ajuster si le premier test révèle une
  incompatibilité.
- `sed` suppose que la ligne `staticPodPath:` dans
  `/var/lib/kubelet/config.yaml` est un champ de premier niveau, sans
  indentation — cohérent avec toutes les sources consultées, mais pas
  vérifié directement sur ce backend précis.
