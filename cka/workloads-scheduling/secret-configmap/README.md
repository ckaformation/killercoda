# Scénario Killercoda — Init containers, Secrets et ConfigMaps

## Contenu

```
init-container-secrets-configmap/
├── index.json
├── intro.md
├── intro-background.sh     # alias k, Secret, Deployment cassé (mountPath /tmp)
├── step1.md / step1-verify.sh   # diagnostic + correction du mountPath
├── step2.md / step2-verify.sh   # ajout d'une clé au Secret + rollout restart
├── step3.md / step3-verify.sh   # ConfigMap créé et monté
└── finish.md
```

## Choix effectués et pourquoi

- **Section `workloads-scheduling`**, comme `workload-scheduling-basics`
  (mêmes thématiques CKA : Deployment, ordonnancement, cycle de vie des
  pods).

- **Backend : `kubernetes-kubeadm-1node`.** Aucune manipulation
  système/control-plane ici, un seul nœud suffit.

- **Panne délibérée : `mountPath: /tmp` au lieu de `/credentials`**,
  demandé explicitement, plutôt qu'une erreur dans la commande `cp`
  elle-même ou dans le nom du Secret référencé : ça isole précisément
  le point d'apprentissage voulu (le montage du volume), sans
  brouiller le diagnostic avec plusieurs causes possibles.

- **`stringData` plutôt que `data` pour ajouter une clé au Secret**
  (étape 2) : évite de demander à l'élève d'encoder une valeur en
  base64 à la main dans `vi`/`kubectl edit`, une manipulation
  fastidieuse et source d'erreurs qui n'apporte rien à l'objectif
  pédagogique réel de cette étape (comprendre le besoin de rollout).

- **`kubectl rollout restart` plutôt que `kubectl delete pod`** pour
  forcer le nouveau pod après modification du Secret : plus
  représentatif de la pratique réelle sur un Deployment (le
  `rollout restart` est justement l'outil prévu pour ce cas précis —
  forcer un rollout sans changement de spec), et permet d'illustrer
  `kubectl rollout status` en cohérence avec `workload-scheduling-basics`.

- **`/config/token` (pas `/config/username` ou `/config/password`)
  comme fichier vérifié à l'étape 2** : cible spécifiquement la
  *nouvelle* clé ajoutée par l'élève, pas une clé déjà copiée avec
  succès dès l'étape 1 — un test sur `username`/`password` à ce stade
  n'aurait rien prouvé de neuf.

- **Étape 3 : ConfigMap monté par simple édition du pod template**
  (pas de `rollout restart` nécessaire, contrairement à l'étape 2) :
  contraste volontaire et explicité dans `step3.md` — ici, la
  modification touche directement le pod template (nouveau
  volume + volumeMount), donc Kubernetes déclenche le rollout
  automatiquement ; à l'étape 2, seul le Secret changeait, pas le pod
  template, d'où la nécessité du `rollout restart` manuel.

- **Noms à thème Star Wars** (`death-star-plans`, `copy-credentials`
  gardé fonctionnel/clair plutôt que thématisé, `holocron-x7` comme
  valeur de token, `obi-wan`/`1138` comme identifiants fictifs),
  conformément à la préférence indiquée pour ce cursus. Les identifiants
  du Secret sont des valeurs fictives et sans rapport avec un système
  réel.

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/workloads/pods/init-containers/
- https://kubernetes.io/docs/concepts/configuration/secret/
- https://kubernetes.io/docs/concepts/configuration/configmap/
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#restarting-a-deployment

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le délai réel avant qu'un pod existant ne voie son volume Secret
  synchronisé (mentionné dans `step2.md` comme non déterminant ici,
  puisque l'init container ne se relance de toute façon pas) dépend du
  kubelet et n'a pas été mesuré sur ce backend précis — ça ne change
  rien à la mécanique enseignée, mais la formulation exacte du délai
  reste indicative.
