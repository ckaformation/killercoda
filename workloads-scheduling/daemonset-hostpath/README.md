# Scénario Killercoda — DaemonSet et hostPath

## Contenu

```
daemonset-hostpath/
├── index.json
├── intro.md
├── intro-background.sh     # taint control-plane retiré, namespace hoth créé
├── step1.md / step1-verify.sh   # écrire et déployer le DaemonSet, vérifier sur les 2 nœuds
├── step2.md / step2-verify.sh   # label + nodeSelector, rm -rf du hostPath orphelin
└── finish.md
```

## Choix effectués et pourquoi

- **Backend : `kubernetes-kubeadm-2nodes`.** Indispensable ici : la
  démonstration entière repose sur la différence de comportement entre
  deux nœuds (`controlplane` couvert puis exclu, `node01` toujours
  couvert).

- **Boucle d'écriture (`while true; do ... sleep 5; done`) plutôt
  qu'une écriture unique au démarrage.** Point technique nécessaire,
  pas explicitement demandé mais indispensable pour que la
  vérification finale ("supprimer le hostPath et constater qu'il ne
  revient pas") ait un sens : avec une écriture unique, supprimer le
  fichier ne permettrait pas de distinguer "le pod ne tourne plus sur
  ce nœud" de "le pod tourne toujours, mais n'a écrit qu'une fois". La
  réécriture périodique rend le test réellement probant.

- **Retrait explicite du taint control-plane par défaut**, comme dans
  tous les scénarios de scheduling de ce chapitre : le DaemonSet de
  l'étape 1 doit couvrir les deux nœuds nativement, sans avoir à gérer
  une `toleration` explicite (qui aurait déplacé l'attention de
  l'exercice vers un sujet différent, déjà couvert par
  `taints-tolerations`).

- **Retrait des pods sur `controlplane` automatique après le
  `nodeSelector`, sans `rollout restart`** : comportement natif du
  contrôleur `DaemonSet`, qui réconcilie en continu la liste des nœuds
  éligibles — contrairement à un `Deployment`, où retirer un label
  n'aurait rien changé sans redéclenchement manuel (cf.
  `node-selector-scheduling`). Souligné explicitement dans `step2.md`
  comme point de contraste.

- **`type: DirectoryOrCreate` sur le hostPath** : évite un échec de
  montage si le répertoire n'existe pas encore sur le nœud au premier
  déploiement.

- **Nom du volume (`scan-log`), chemin hostPath
  (`/var/log/probe-droid`) et contenu du fichier écrit, laissés à mon
  choix** (explicitement autorisé par la demande) : thème Star Wars
  cohérent avec le reste du cursus — un DaemonSet, présent sur chaque
  nœud pour y effectuer une tâche identique, correspond bien à l'image
  d'une sonde impériale envoyée systématiquement en reconnaissance,
  d'où le namespace `hoth` (planète où atterrit justement une sonde de
  ce type dans la saga) et le nom `probe-droid`.

- **Label `mission=recon` sur `node01`** : cohérent avec le thème
  "sonde en reconnaissance", pas de contrainte technique particulière
  sur le nom choisi.

- **`command: [bash, -c, ...]` plutôt que `[/bin/bash, -c, ...]`**
  (correctif appliqué après un premier test réel) : sur l'image
  `bash:5`, le binaire n'est pas à l'emplacement `/bin/bash` — appeler
  simplement `bash` et laisser le `PATH` du conteneur le résoudre
  fonctionne, alors que le chemin absolu provoquait une erreur "not
  found" au démarrage du conteneur.

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/
- https://kubernetes.io/docs/concepts/storage/volumes/#hostpath

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le comportement "un DaemonSet retire ses pods des nœuds devenus
  inéligibles sans intervention manuelle" est un comportement
  documenté et stable du contrôleur `DaemonSet`, mais je n'ai pas pu le
  vérifier en conditions réelles sur ce backend précis.
- Le délai de reconciliation exact du contrôleur `DaemonSet` après une
  modification de `nodeSelector` n'est pas garanti à une valeur
  précise ; `step2.md` ne fixe pas de timeout strict à ce sujet (pas de
  `kubectl wait` dédié dans `step2-verify.sh` pour cette transition
  spécifique, en dehors des vérifications d'état final).
