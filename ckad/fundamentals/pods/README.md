# Scénario Killercoda — Pod : les fondamentaux, du kubectl au runtime

## Contenu

```
pod-fundamentals/
├── index.json                   # backend kubernetes-kubeadm-2nodes, 3 étapes
├── intro.md                     # explication de ce qu'est un pod
├── intro-background.sh          # alias k, taint control-plane, crictl sur node01
├── step1.md / step1-verify.sh   # k run bb-8 (nginx:alpine), k describe, k logs
├── step2.md / step2-verify.sh   # placement sur node01 (taint), ssh node01, crictl pods/ps/logs
├── step3.md / step3-verify.sh   # crictl rm -f (le kubelet recrée), puis k delete pod (le pod ne revient pas)
└── finish.md
```

## Choix effectués

- **Backend `kubernetes-kubeadm-2nodes`** : il faut un worker (`node01`) et le taint par défaut du `controlplane`.
- **Pod `bb-8`, image `nginx:alpine`** (nom Star Wars ; image déjà utilisée dans les autres scénarios). Création par `k run` avec un gabarit `<A_COMPLETER>` non cliquable, comme dans les autres scénarios pédagogiques.
- **Fichiers repères sur `node01`.** Les étapes 2 et 3 consistent surtout à observer, ce qu'un script de vérification ne peut pas constater directement. L'élève enregistre donc l'identifiant du container avant la suppression (`/root/bb-8-container-id`) puis celui du container recréé (`/root/bb-8-new-container-id`). Les vérifications s'appuient dessus :
  - étape 2 : le fichier existe et son contenu correspond à un container `bb-8` en cours d'exécution ;
  - étape 3 : les deux identifiants existent et diffèrent, l'ancien container n'existe plus, le pod est supprimé et plus aucun container `bb-8` ne tourne.
- **Comparaison des identifiants plutôt que du compteur `RESTARTS`.** Je ne sais pas si `kubectl get pod` incrémente `RESTARTS` après un `crictl rm -f` : le texte n'en parle donc pas.
- **Préparation** : `k` sur `controlplane`, taint `node-role.kubernetes.io/control-plane:NoSchedule` (re)posé avec `--overwrite`, `crictl` sur `node01` installé seulement s'il est absent, avec `/etc/crictl.yaml` vers containerd. La connexion `ssh -o StrictHostKeyChecking=no` du script enregistre aussi `node01` dans `known_hosts`.
- **Pas de `wait-for-prep.sh`** : la préparation est courte et l'élève ne touche à `crictl` qu'à l'étape 2.
- **Les vérifications ne prouvent pas que l'élève a lu les sorties** de `k describe`, `k logs` ou `crictl logs`, seulement l'état final des objets et les fichiers repères.

## Tested on paper only — hypothèses à vérifier au premier passage

Je n'ai pas pu exécuter ce scénario contre un cluster. Ce qui a été testé : la syntaxe de tous les scripts (`bash -n`) et la logique des trois scripts de vérification, avec de faux `kubectl`, `ssh` et `crictl` (cas de succès et chacun des cas d'échec). Ce qui reste à vérifier :

- **Taint par défaut du `controlplane`** sur le backend 2 nœuds : le scénario `taints-tolerations` le retirait explicitement, ce qui suggère qu'il est présent par défaut. La préparation le repose de toute façon.
- **`crictl` sur `node01`** : installation de secours en `v1.36.0` (la version indiquée pour le cours), depuis GitHub. Si l'URL de la release est inexacte, `crictl` serait absent à l'étape 2.
- **`ssh node01` sans question** d'empreinte, et accès `root` : supposé, comme dans les scénarios précédents. L'énoncé prévoit de répondre `yes` si la question apparaît.
- **Logs de nginx au démarrage** : j'attends des lignes de l'entrypoint de l'image (`/docker-entrypoint.sh: ...`). Les scripts de vérification n'en dépendent pas.
- **Délai de recréation du container** par le kubelet après `crictl rm -f` : attendu de l'ordre de quelques secondes ; l'énoncé invite à relancer `crictl ps` si besoin.
- **Même `POD ID` après `crictl rm -f`** : l'étape 3 affirme que la sandbox du pod ne change pas, seul le container est remplacé. C'est le comportement que j'attends du kubelet, non observé.
- **Options de `crictl`** : `crictl ps -q` affiche les identifiants complets, `--name` filtre par expression régulière, `crictl pods --name` existe, `crictl rm -f` force la suppression. Écrit de mémoire.
- **Accès à Docker Hub** depuis `node01` pour `nginx:alpine`, comme dans les scénarios précédents.
- **Lien du `finish.md`** : URL canonique de la documentation des Pods, non vérifiée par un fetch.
