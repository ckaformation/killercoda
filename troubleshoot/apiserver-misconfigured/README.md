# Scénario Killercoda — kube-apiserver, 3 erreurs cumulées

## Contenu

```
apiserver-troubleshoot-3errors/
├── index.json
├── intro.md
├── intro-background.sh   # installe crictl + sauvegarde + injecte les 3 erreurs
├── step1.md               # 3 dropdowns indice (1 par erreur) + 1 dropdown solution
├── step1-verify.sh
└── finish.md
```

## Corrections suite à retour de Pierrot

- **Description allégée** (`step1.md`, `intro.md`) : la version
  initiale expliquait trop explicitement la logique en cascade des 3
  erreurs avant même que l'élève ne commence — ça déflorait une partie
  de la découverte. Le texte visible est désormais minimal ("le
  manifest est mal configuré en 3 points, répare-les"), la mécanique
  en cascade n'étant expliquée que dans le dropdown Solution.
- **`vim` plutôt que `sed`** pour les 3 corrections dans le dropdown
  Solution : chaque fix ouvre `vim` sur le manifest, avec l'édition à
  faire décrite en prose, plutôt qu'une commande `sed` automatique en
  une ligne — plus proche d'une pratique réaliste de troubleshooting.
  `intro-background.sh` garde `sed`, puisque c'est un script
  d'automatisation (l'injection des erreurs), pas une instruction
  suivie par l'élève.

## Choix effectués et pourquoi

- **Une seule étape** (contrairement au scénario précédent à 3
  étapes) : la demande décrit un seul défi combiné (3 erreurs
  simultanées à trouver et corriger), pas une progression en phases
  distinctes.
- **`crictl` réinstallé** (même version `v1.36.0` que le scénario
  précédent) : chaque scénario Killercoda est un environnement isolé,
  donc pas de dépendance possible à l'installation faite dans un
  scénario précédent.
- **Retrait temporaire du fichier manifest avant d'injecter les 3
  erreurs**, plutôt qu'une édition en place : si kubelet ne parvient
  pas à parser le nouveau YAML (à cause de `metadata;`), il pourrait
  simplement ignorer la mise à jour et laisser l'ancien conteneur
  (sain) tourner sans redémarrer — ce qui aurait supprimé tout
  symptôme observable au démarrage. Retirer le fichier force kubelet à
  arrêter le pod existant ; le remettre (cassé) garantit qu'il n'y a
  plus de conteneur `kube-apiserver` sain en arrière-plan.
- **Découverte en cascade assumée et explicitée** (dans `intro.md` et
  la solution) : par construction, tant que `metadata;` n'est pas
  corrigé, kubelet ne peut pas charger le fichier comme un pod valide
  — donc les erreurs 2 et 3 (argument inconnu, certificat manquant) ne
  peuvent pas se manifester au niveau du conteneur avant que l'erreur
  1 soit résolue. C'est volontaire et réaliste, mais ça veut dire que
  l'élève ne verra probablement pas les 3 symptômes en même temps dès
  le départ.
- **`--midichlorians=9000`** comme argument inconnu (thème Star Wars),
  **`/etc/kubernetes/pki/apiserver-WRONG.crt`** comme chemin de
  certificat erroné (fichier garanti inexistant, plutôt qu'un fichier
  existant mais sémantiquement incorrect — plus simple à diagnostiquer
  et déterministe).
- **Indices volontairement minimalistes** (une phrase, une question),
  conformément à la demande explicite ("vraiment il faut que ça reste
  un indice, rien de plus") — la solution, elle, est complète et
  explique la logique en cascade.
- **`step1-verify.sh` basé sur `crictl` et une lecture directe du
  manifest, pas sur `kubectl`** : cohérent avec l'esprit du scénario
  (ne pas dépendre de l'apiserver pour diagnostiquer), même si à ce
  stade final `kubectl` devrait normalement refonctionner. J'ai choisi
  d'inclure un `verify` cette fois (contrairement au scénario
  précédent) car l'état final (les 3 erreurs corrigées) est
  réellement vérifiable de façon fiable — à la différence des étapes
  intermédiaires du scénario précédent, où l'apiserver était
  délibérément laissé cassé à la fin de chaque étape. Dis-moi si tu
  préfères retirer ce `verify` pour rester cohérent avec le choix
  "pas de vérification" du scénario précédent.

## Sources utilisées

- Installation de `crictl` et son endpoint containerd : déjà vérifié
  pour le scénario précédent (`apiserver-troubleshoot`).
- Chemin par défaut `/etc/kubernetes/pki/apiserver.crt` pour
  `--tls-cert-file` sous kubeadm : connaissance générale Kubernetes/
  kubeadm (structure standard du répertoire PKI), non re-vérifiée par
  recherche dédiée dans cette conversation.

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents.
- **Comportement de kubelet face à un fichier temporairement absent
  puis remis, cassé** : je pars du principe que l'absence du fichier
  déclenche bien l'arrêt du pod existant avant que la version cassée
  ne soit prise en compte (échouant alors silencieusement à la
  recréer). C'est le point le plus important à valider en conditions
  réelles pour ce scénario — s'il s'avère que l'ancien conteneur
  survit malgré tout, l'élève n'aurait aucun symptôme au départ.
- **Ordre exact de la cascade** (YAML → argument → certificat) :
  déduit du raisonnement sur le fonctionnement de kubelet et de
  `kube-apiserver`, non observé en conditions réelles.
- **`crictl ps --name kube-apiserver -q`** : suppose que le nom du
  conteneur (tel qu'exposé par `crictl`) contient bien la chaîne
  `kube-apiserver` — comportement attendu standard sous kubeadm/
  containerd, non re-vérifié spécifiquement sur ce backend.
