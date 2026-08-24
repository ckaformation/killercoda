# Scénario Killercoda — Workloads : Pod, Deployment, StatefulSet, rollouts

## Contenu

```
workload-scheduling-basics/
├── index.json
├── intro.md
├── intro-background.sh     # alias k uniquement
├── step1.md / step1-verify.sh   # Pod nu (r2d2)
├── step2.md / step2-verify.sh   # Deployment (x-wing-fleet) + scaling via kubectl edit
├── step3.md / step3-verify.sh   # 2 incréments de révision + rollout undo --to-revision=n-2
├── step4.md / step4-verify.sh   # StatefulSet (jedi-archive, redis:7-alpine) + CPU request + OnDelete
├── step5.md / step5-verify.sh   # rollout undo du StatefulSet + OnDelete
└── finish.md
```

## Choix effectués et pourquoi

- **Découpage en 5 étapes Killercoda**, alors que la demande initiale
  parlait de 3 phases : chaque sous-tâche décrite (pod nu ; déploiement
  + scaling ; deux incréments de révision + rollback ; StatefulSet +
  edit + delete ; rollback du StatefulSet) est substantielle et mérite
  son propre point de contrôle (`verify.sh`), plutôt que d'être noyée
  dans une étape plus large.

- **Incréments de révision via une variable d'environnement
  (`SQUADRON_VERSION`) plutôt que via des tags d'image nginx
  différents.** Je ne pouvais pas garantir avec certitude l'existence
  actuelle de tags nginx précis sur Docker Hub (les tags de versions
  spécifiques sont parfois retirés avec le temps), et une image
  introuvable aurait cassé tout le scénario. N'importe quelle
  modification de `spec.template` déclenche une nouvelle révision, pas
  seulement un changement d'image — la variable d'environnement remplit
  exactement le même rôle pédagogique sans dépendance externe fragile.

- **`kubectl rollout undo --to-revision=1` (pas `--to-revision=0` ni
  sans argument)** : avec 3 révisions (création + 2 modifications),
  "revenir de 2 révisions en arrière" signifie cibler explicitement la
  révision 1 (3 − 2), pas simplement "la précédente" (qui reviendrait à
  la révision 2, un seul cran en arrière). Vérifié via recherche : un
  `rollout undo --to-revision=N` restaure le **contenu** de la révision
  N mais crée toujours un **nouveau** numéro de révision, le plus haut
  — jamais un recul du numéro lui-même. `step3.md` l'explique
  explicitement, et `step3-verify.sh` vérifie le **contenu** (valeur de
  la variable d'environnement), jamais un numéro de révision précis,
  pour cette raison.

- **StatefulSet accompagné d'un Service headless** (`clusterIP: None`),
  comme dans `static-pods` et `operator-namespace-provisioner` : requis
  par la spec de tout StatefulSet.

- **`updateStrategy: OnDelete` appliqué symétriquement aux étapes 4 et
  5** : la demande initiale ne mentionnait le `delete` manuel que pour
  la modification du CPU request (étape 4), mais le même principe
  s'applique nécessairement au rollback (étape 5) — `OnDelete` ne fait
  aucune distinction entre "nouveau changement" et "rollback", les deux
  ne sont que des mises à jour du pod template. Je l'ai donc rendu
  explicite aussi à l'étape 5, plutôt que de laisser l'élève découvrir
  la surprise sans explication.

- **CPU request 100m → 250m → 100m** (valeurs rondes, faciles à
  distinguer visuellement et à vérifier par égalité de chaîne exacte
  dans les `verify.sh`).

- **Noms des objets à thème Star Wars** (`r2d2`, `x-wing-fleet`,
  `jedi-archive`), conformément à la préférence indiquée pour les
  scénarios de ce cursus. Les images conteneur elles-mêmes
  (`nginx:alpine`, `redis:7-alpine`) restent des images réelles,
  choisies pour leur légèreté et fiabilité de pull, sans lien avec le
  thème.

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
- https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/kubectl_rollout_undo/

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le comportement de `kubectl rollout undo` sur un StatefulSet (étape
  5) est supposé analogue à celui d'un Deployment (mêmes
  sous-commandes `rollout history`/`rollout status`/`rollout undo`,
  bien documentées pour les deux types), mais je n'ai pas de
  confirmation testée en conditions réelles spécifiquement pour un
  StatefulSet en configuration `OnDelete`.
