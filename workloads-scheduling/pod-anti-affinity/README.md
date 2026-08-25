# Scénario Killercoda — Pod Anti-Affinity

## Contenu

```
pod-anti-affinity/
├── index.json
├── intro.md
├── intro-background.sh     # taint control-plane retiré, seul yoda tourne, luke.yaml déposé (pas appliqué)
├── step1.md / step1-verify.sh   # complétion de luke.yaml (anti-affinity) + premier lancement
├── step2.md / step2-verify.sh   # yoda-2 sur controlplane, observation IgnoredDuringExecution, delete+recreate de luke
└── finish.md
```

## Choix effectués et pourquoi

- **Même pattern que `pod-affinity` pour `luke`** : il n'existe pas au
  démarrage, l'élève complète `/root/luke.yaml` puis le lance pour la
  première fois — cohérence délibérée avec le correctif apporté à ce
  scénario précédent.

- **Point ajouté de moi-même, non explicitement demandé : l'observation
  de `IgnoredDuringExecution`** (étape 2, points 3-4). La demande
  initiale décrit directement l'objectif final ("luke ne trouve plus de
  nœud"), mais atteindre cet état exige un point technique
  intermédiaire : si `luke` tourne déjà (ce qui est le cas après
  l'étape 1) au moment où `yoda-2` apparaît sur `controlplane`, il
  **ne sera pas évincé** — `requiredDuringSchedulingIgnoredDuringExecution`
  ne s'applique qu'au moment du scheduling, jamais en continu. Sans
  `kubectl delete pod luke` puis recréation, la démonstration finale ne
  se produirait pas : `luke` continuerait de tourner tranquillement sur
  `controlplane`, contredisant l'objectif de l'exercice. Je l'ai rendu
  explicite plutôt que de le contourner silencieusement dans le script
  de vérification.

- **`yoda-2` : nom imposé, copie de `yoda.yaml`, seuls `metadata.name` et
  `spec.nodeName` changent, le label `app: yoda` reste identique**,
  conformément à la demande ("on ne touche pas au label").

- **Retrait explicite du taint control-plane par défaut**, comme dans
  `pod-affinity`, `node-selector-scheduling` et `taints-tolerations` :
  `luke` doit pouvoir se placer sur `controlplane` via le scheduler
  normal à l'étape 1.

- **`kubectl describe pod luke` en fin d'étape 2** (pas explicitement
  demandé) : ajouté pour montrer que Kubernetes explique concrètement,
  via ses `Events`, pourquoi un pod reste `Pending` — un réflexe de
  diagnostic transférable à d'autres causes de blocage de scheduling.

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le texte exact du message d'événement `FailedScheduling` mentionné
  dans `step2.md` ("didn't match pod anti-affinity rules") est décrit
  de façon approximative, pas cité comme une garantie littérale — le
  comportement général (blocage motivé et visible dans les Events) est
  en revanche stable et bien documenté.
