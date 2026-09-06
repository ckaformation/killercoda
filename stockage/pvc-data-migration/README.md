# Scénario Killercoda — Migration de PVC entre StorageClass

## Contenu

```
pvc-migration-storageclass/
├── index.json
├── intro.md
├── intro-background.sh   # namespace + local-path-provisioner + StorageClass retain-storage + Deployment echo-base
├── step1.md / step1-verify.sh   # création du nouveau PVC (retain-storage)
├── step2.md / step2-verify.sh   # Job bash:5 de copie /old-data -> /new-data
└── step3.md / step3-verify.sh   # bascule du Deployment + nettoyage (Job + ancien PVC)
└── finish.md
```

## Choix effectués et pourquoi

- **Backend `kubernetes-kubeadm-1node`** : `local-path-provisioner`
  n'y est pas préinstallé (contrairement au backend 2 nœuds), donc
  `intro-background.sh` l'installe lui-même (même manifeste `v0.0.37`
  que `storage-reclaim-policy`).
- **Pas de pattern sentinel/`wait-for-prep.sh`** : cohérent avec le
  retrait décidé sur le scénario précédent (`statefulset-node-affinity
  -troubleshoot`) suite à un souci de synchronisation qui traînait en
  longueur sans raison apparente.
- **Un seul `{{exec}}` par bloc, jamais deux commandes à la suite** :
  appliqué strictement dans les 3 fichiers d'étapes, conformément à la
  consigne.
- **Namespace `hoth`, Deployment `echo-base`, fichier
  `rebel-plans.txt`** : thème Star Wars (évacuation de la base Echo
  sur Hoth = migration de données, le parallèle m'a semblé naturel).
- **Contenu du fichier de données non demandé explicitement** :
  j'ai choisi d'écrire un seul fichier (`rebel-plans.txt`) au
  démarrage du Deployment pour avoir quelque chose de concret à faire
  migrer et vérifier ; à adapter si tu veux un jeu de données plus
  riche (plusieurs fichiers, sous-répertoires...).
- **`echo-base-data-retain` comme nom suggéré pour le nouveau PVC**
  (étape 1) : donné explicitement dans le template plutôt que laissé
  au choix de l'élève, pour que les étapes 2 et 3 (qui le référencent
  par son nom dans leurs propres templates) restent cohérentes sans
  complexifier les scripts de vérification avec une découverte
  dynamique supplémentaire.
- **`step2-verify.sh` : vérification des données sur disque avec repli
  générique** si `spec.hostPath.path` du PV est vide, comme dans les
  scénarios de stockage précédents. Ce repli ne distingue pas
  précisément ancien vs nouveau PVC (il vérifie juste qu'un fichier de
  ce nom existe quelque part sous `/opt/local-path-provisioner`) : moins
  rigoureux que la vérification directe par PV, mais reste un filet de
  sécurité raisonnable plutôt qu'un blocage total.
- **`step3-verify.sh` recherche le volume du Deployment par présence
  d'un champ `persistentVolumeClaim`** plutôt que par index fixe
  (`volumes[0]`), afin de rester correct même si la structure exacte
  du Deployment édité par l'élève varie légèrement.

## Sources utilisées

- Contenu/version du manifeste `rancher/local-path-provisioner` :
  déjà vérifié pour le scénario `storage-reclaim-policy` (README
  correspondant, sources GitHub officielles).

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents.
- **`cp -av /old-data/. /new-data/` avec l'image `bash:5`** : `cp` et
  ses options `-a`/`-v` sont des utilitaires GNU coreutils standards,
  présents par défaut sur l'image `bash:5` (basée sur une distribution
  Debian) — comportement attendu, non re-testé spécifiquement pour ce
  tag précis.
- **Pas de vérification explicite que le Deployment ne mélange pas
  ancien et nouveau PVC en même temps** (deux volumes simultanés) :
  `step3-verify.sh` se contente de vérifier qu'AU MOINS un volume
  `persistentVolumeClaim` pointe vers le nouveau PVC ; un élève qui
  laisserait les deux volumes montés en même temps passerait quand
  même la vérification. Non bloquant pour l'objectif pédagogique visé,
  mais signalé au cas où tu voudrais un contrôle plus strict.
