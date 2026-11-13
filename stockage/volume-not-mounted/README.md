# Scénario Killercoda — StatefulSet, drain de nœud & nodeAffinity de PV

## Contenu

```
statefulset-node-affinity-troubleshoot/
├── index.json
├── intro.md
├── intro-background.sh   # namespace kamino + local-path-provisioner + StatefulSet clone-vat
├── step1.md / step1-verify.sh   # cordon/drain node01 (explicite) + taint/toleration (2 indices + solution)
└── step2.md / step2-verify.sh   # nodeAffinity du PV (1 indice + solution)
└── finish.md
```

## Choix effectués et pourquoi

- **Pattern sentinel/`wait-for-prep.sh` retiré de ce scénario**
  (suite à retour de Pierrot : la synchronisation traînait en
  longueur malgré un environnement réellement prêt à la vérification
  manuelle — cause exacte non identifiée). `intro-background.sh`
  continue de préparer l'environnement en arrière-plan comme le prévoit
  Killercoda, mais sans étape de confirmation explicite côté élève :
  l'élève commence directement l'étape 1, en s'appuyant sur le temps
  de lecture de l'intro pour laisser le script d'arrière-plan
  terminer. `step1-verify.sh` ne vérifie donc plus de sentinel.

- **Backend `kubernetes-kubeadm-2nodes`** : nécessaire pour avoir deux
  nœuds distincts (`controlplane` + `node01`). Chaîne d'`imageid` non
  confirmée directement (contrairement à `kubernetes-kubeadm-1node`,
  déjà validé sur d'autres scénarios de ce cursus) — à vérifier/
  corriger si besoin, sur le même principe que la correction
  `host01`/`controlplane` déjà rencontrée.
- **Namespace `kamino`, StatefulSet `clone-vat`** : thème Star Wars
  cohérent avec le reste du cursus (Kamino = planète de clonage des
  troopers, un StatefulSet qui "clone" des instances stables).
- **`local-path-provisioner` déjà installé par défaut sur l'image
  `kubernetes-kubeadm-2nodes`** (corrigé suite à retour de Pierrot) :
  `intro-background.sh` ne l'installe donc plus lui-même, contrairement
  à `storage-reclaim-policy` (qui tourne sur le backend 1 nœud, où il
  n'est pas préinstallé). Le script se contente de vérifier que la
  `StorageClass local-path` est bien présente (avec une courte boucle
  d'attente, au cas où elle mettrait quelques secondes à apparaître au
  démarrage de la VM), sans réinstaller quoi que ce soit. L'annotation
  `is-default-class` n'est plus gérée non plus : elle n'a pas d'utilité
  ici puisque le StatefulSet référence `storageClassName: local-path`
  explicitement, sans dépendre d'une StorageClass par défaut.
- **`node-role.kubernetes.io/control-plane:NoSchedule`** comme clé de
  taint attendue : c'est la clé standard depuis Kubernetes 1.20+
  (remplace l'ancienne `node-role.kubernetes.io/master`), cohérente
  avec la version 1.35.1 déjà notée pour ce cursus.
- **Suppression explicite du pod après édition du StatefulSet**
  (étape 1, dans la solution) : ajouter une `toleration` au template
  d'un StatefulSet ne modifie pas rétroactivement un pod déjà créé et
  actuellement `Pending` — le contrôleur ne le recrée pas forcément
  immédiatement avec la nouvelle définition. Comme pour les scénarios
  précédents (rollout restart après `kubectl set env`, etc.), une
  suppression manuelle explicite lève toute ambiguïté sur le timing.
- **Étape 1 avec cordon/drain donnés explicitement, mais
  investigation "pourquoi Pending" vague avec 2 indices + solution** :
  conforme à la demande — la préparation à la maintenance n'est pas un
  mystère à percer, seule la conséquence (taint/toleration) l'est.
- **Étape 2 avec 1 seul indice + solution**, conformément à la
  demande, sur le nodeAffinity du PV.
- **`step2-verify.sh` vérifie le `nodeName` réel du pod ET, si
  possible, le `nodeAffinity` du PV** : double vérification pour plus
  de robustesse, mais la vérification du PV reste non bloquante si le
  champ est absent/différemment structuré (`if [ -n "$PV_NODE" ]`),
  pour ne pas faire échouer tout le script sur un détail de structure
  que je n'ai pas pu tester en conditions réelles.
- **PVC nommé `data-clone-vat-0`** : convention de nommage standard
  des `volumeClaimTemplates` d'un StatefulSet
  (`<nom-template>-<nom-sts>-<ordinal>`), donnée explicitement dans le
  texte de l'étape 2 plutôt que laissée à deviner, pour rester dans
  l'esprit "étape 2 pédagogique/guidée" plutôt que pur troubleshooting
  sur ce point précis.

## Sources utilisées

- Comportement de `nodeAffinity` par défaut sur les PV créés par
  `rancher/local-path-provisioner` (clé `kubernetes.io/hostname`,
  volume accessible uniquement sur le nœud de provisioning) :
  confirmé sur le README officiel actuel
  (`github.com/rancher/local-path-provisioner`), y compris un exemple
  concret de conflit de ce type dans les issues du projet (`0/4 nodes
  are available: ... volume node affinity conflict`).
- Clé de taint control-plane moderne
  (`node-role.kubernetes.io/control-plane`) : connaissance générale
  Kubernetes (changement introduit en 1.20), non re-vérifiée par une
  recherche dédiée dans cette conversation.
- Règle de mutabilité partielle des `tolerations` sur un Pod déjà créé
  (ajout autorisé, pas de modification/suppression) : connaissance
  générale Kubernetes, non re-vérifiée par une recherche dédiée dans
  cette conversation — c'est justement pour cette raison que la
  solution passe par une suppression explicite du pod plutôt que de
  compter sur une éventuelle mise à jour en place.

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Sans étape de synchronisation explicite, l'élève pourrait démarrer
  l'étape 1 avant que `clone-vat-0` soit réellement `Running`** sur
  `node01` (pull de l'image `busybox:1.36`, création du PVC/PV...) si
  la lecture de `intro.md` est très rapide. Risque jugé faible et
  accepté suite à la demande de Pierrot, mais à surveiller si des
  échecs de `step1-verify.sh` apparaissent alors que l'élève a bien
  suivi les instructions — dans ce cas, relancer la vérification après
  quelques secondes suffit.
- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents.
- **`imageid` du backend 2 nœuds** : à confirmer/corriger (voir plus
  haut).
- **Comportement exact du contrôleur StatefulSet face à un pod
  `Pending` dont le template vient de changer** (recréation
  automatique ou non) : je n'ai pas testé ce cas précis en conditions
  réelles ; la suppression manuelle du pod dans la solution contourne
  cette incertitude plutôt que d'en dépendre.
- **Régression connue sur le `nodeAffinity` dans la version 0.0.29**
  du provisioner (issue GitHub `#454`) : je pars du principe qu'elle
  est résolue dans la version `v0.0.37` utilisée ici, sans
  confirmation indépendante ligne à ligne du changelog entre ces deux
  versions.
