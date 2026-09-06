# Scénario Killercoda — Troubleshooting PVC & PostgreSQL

## Contenu

```
storage-pvc-troubleshoot/
├── index.json
├── intro.md
├── intro-background.sh   # namespace + PV (ReadOnlyMany) + PVC (ReadWriteOnce)
├── step1.md / step1-verify.sh   # troubleshoot binding PV/PVC (vague, sans indice)
└── step2.md / step2-verify.sh   # template Deployment PostgreSQL à compléter
└── finish.md
```

## Choix effectués et pourquoi

- **Provisioning statique (PV + PVC manuels), `storageClassName: ""`
  sur les deux** : volontaire, pour isoler strictement la seule
  variable en cause (l'incompatibilité d'`accessModes`) sans risquer
  qu'un `StorageClass` par défaut intercepte la demande via l'admission
  controller `DefaultStorageClass`. Ce cluster n'a par ailleurs aucun
  provisioner dynamique installé (contrairement au scénario
  `storage-reclaim-policy`).
- **Namespace `jedi-archives`, PV `holocron-pv`, PVC
  `holocron-storage`** : noms imposés (pré-existants, pas choisis par
  l'élève), cohérents avec le thème Star Wars du cursus.
- **`step1-verify.sh` vérifie que le PV lié supporte bien
  `ReadWriteOnce`**, plutôt que de se contenter du statut `Bound` du
  PVC : un PVC peut aussi passer à `Bound` si l'élève modifie plutôt
  le PVC pour demander `ReadOnlyMany` (ce qui correspondrait alors au
  PV existant) — techniquement valide pour Kubernetes, mais
  contraire à l'esprit de l'exercice, et incompatible avec l'usage
  réel prévu à l'étape 2 (PostgreSQL a besoin d'écrire). Le script
  guide donc explicitly vers la correction du PV, pas seulement vers
  un PVC "Bound" par n'importe quel moyen.
- **Étape 1 volontairement sans le moindre indice** (pas de menu
  dépliant, contrairement au scénario CoreDNS), conformément à la
  demande explicite — l'élève doit comparer lui-même
  `kubectl get pv/pvc -o yaml` pour repérer le mismatch
  d'`accessModes`.
- **Template de Deployment fourni avec des `<A_COMPLETER>`** à
  l'étape 2 (image, valeur de `POSTGRES_PASSWORD`, `mountPath`,
  `claimName`) : structure YAML donnée pour rester pédagogique
  (l'objectif est de comprendre comment brancher un PVC sur un
  conteneur, pas de tester la mémorisation du schéma complet d'un
  Deployment), tout en laissant les 4 points clés de la consigne à
  l'élève.
- **`POSTGRES_PASSWORD` en valeur littérale (`value: secret`)**,
  conforme à la demande explicite, plutôt qu'une référence à un
  Secret — plus simple pédagogiquement pour cet exercice, même si ce
  n'est pas une pratique recommandée en production (mot de passe en
  clair dans le manifeste). Non signalé dans `step2.md` pour ne pas
  s'écarter de la consigne donnée, mais mentionnable à l'oral si tu
  veux insister sur ce point.

## Sources utilisées

- Comportement du binding PV/PVC (mismatch d'`accessModes` ⇒ PVC
  reste `Pending`, admission controller `DefaultStorageClass` qui
  peut intercepter un PVC sans `storageClassName` explicite) :
  connaissance générale Kubernetes, non re-vérifiée par une recherche
  dédiée dans cette conversation.

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents.
- **Message d'erreur exact dans les `Events` du PVC** en cas de
  mismatch d'`accessModes` (générique, du type "no persistent volumes
  available for this claim and no storage class is set") : non
  reproduit/observé en conditions réelles pour cette conversation —
  `step1.md` reste volontairement vague sur ce point plutôt que
  d'annoncer un message précis non garanti.
- **Absence de StorageClass par défaut sur ce backend** dans son état
  de base (avant toute installation par ce scénario) : je pars du
  principe qu'un `kubernetes-kubeadm-1node` fraîchement démarré n'a
  aucun provisioner/StorageClass par défaut préinstallé, cohérent avec
  un kubeadm standard, mais non re-vérifié spécifiquement sur ce
  backend Killercoda pour cette conversation.
