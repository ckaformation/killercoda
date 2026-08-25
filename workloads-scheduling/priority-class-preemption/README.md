# Scénario Killercoda — PriorityClass et Pod Preemption

## Contenu

```
priority-class-preemption/
├── index.json
├── intro.md
├── intro-background.sh     # PriorityClasses, namespaces, pods, filler dimensionné dynamiquement
├── step1.md / step1-verify.sh   # identifier et supprimer le pod le plus prioritaire
├── step2.md / step2-verify.sh   # créer flagship, observer la préemption de star-destroyer
└── finish.md
```

## Choix effectués et pourquoi — le point le plus délicat de ce scénario

**Le problème de fond** : la demande précise que le pod existant (`star-destroyer`)
et le nouveau pod (`flagship`) doivent tous les deux demander `1Gi` de
mémoire. Mais si le nœud dispose de largement plus de 2Gi de mémoire
allouable (ce qui est plausible selon le backend Killercoda), les deux
pods à 1Gi cohabiteraient sans jamais avoir besoin de préemption — et
l'exercice ne démontrerait rien.

**La solution retenue** : un pod technique, `filler` (namespace
`default`, invisible dans le récit), dont la demande mémoire est
**calculée dynamiquement** dans `intro-background.sh` à partir de la
mémoire allouable réelle du nœud (`kubectl get node -o
jsonpath='{.status.allocatable.memory}'`), pour ne laisser qu'environ
1,5Gi de libre après lui — juste assez pour `star-destroyer` (1Gi)
seul, pas assez pour `star-destroyer` + `flagship` (1Gi chacun)
simultanément. Une marge de sécurité fixe (300Mi) est soustraite pour
tenir compte des composants système déjà présents sur le nœud.

**Pourquoi `filler` porte `priorityClassName: level3`** (la même que
`flagship`, pas une priorité basse) : la préemption ne cible que les
pods de priorité **strictement inférieure** au pod en attente. Si
`filler` avait une priorité plus basse que `star-destroyer`, il serait
lui-même la cible préférentielle de la préemption (étant le plus bas),
et `star-destroyer` ne serait jamais touché — ce qui casserait
entièrement la démonstration voulue. En lui donnant la même priorité
que `flagship`, `filler` devient totalement protégé, et
`star-destroyer` (`level2`, seul pod de priorité strictement
inférieure à `flagship`) devient la seule cible possible.

**Garde-fou sur les nœuds très contraints** : si la mémoire allouable
du nœud est inférieure à ~2,2Gi, `filler` n'est pas créé du tout,
plutôt que de risquer de saturer le nœud au point d'empêcher même
`star-destroyer` de démarrer correctement. Dans ce cas extrême,
l'étape 2 pourrait ne pas déclencher de préemption (si les deux pods à
1Gi tiennent malgré tout) — limite assumée, documentée ci-dessous.

## Autres choix

- **Backend : `kubernetes-kubeadm-1node`.** `PriorityClass` et la
  préemption sont des mécanismes cluster/nœud, pas liés à une
  distinction multi-nœuds ; un seul nœud simplifie tout le
  raisonnement sur la capacité mémoire disponible.

- **Trois `PriorityClass` (`level1`/100, `level2`/1000,
  `level3`/10000)** : `level1`/`level2` demandés explicitement pour
  l'étape 1 ; `level3` ajouté pour l'étape 2, qui demande explicitement
  une priorité "plus élevée" que `level2`.

- **Namespaces `rebellion` et `empire`**, noms à thème Star Wars
  (liberté laissée explicitement par la demande), cohérents avec les
  pods qu'ils contiennent (`x-wing-pilot`/`rebel-commander` côté
  Rébellion ; `star-destroyer`/`flagship` côté Empire — un vaisseau
  amiral qui prend le pas sur un simple croiseur illustre bien l'idée
  de priorité supérieure).

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/
- https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ (mémoire allouable des nœuds)

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- **C'est le point le plus important à vérifier en priorité** : le
  calcul dynamique de `filler` n'a pas pu être testé sur la mémoire
  réelle du backend Killercoda. La logique a été testée isolément
  (script bash exécuté avec plusieurs valeurs de mémoire allouable
  plausibles, de ~1,8Gi à ~7,6Gi, produisant dans tous les cas une
  marge libre finale d'environ 700-800Mi — insuffisante pour un second
  pod à 1Gi, donc favorable à la préemption), mais pas contre la valeur
  réelle du nœud Killercoda.
- Le garde-fou à 2,2Gi (pas de `filler` créé en dessous) n'a pas non
  plus été validé en conditions réelles ; si le nœud tombe dans cette
  zone, l'étape 2 pourrait ne pas produire de préemption — à surveiller
  au premier test.
- Les marges utilisées (300Mi de sécurité système, 1536Mi de libre
  visé) sont des valeurs raisonnables mais arbitraires, pas mesurées
  sur ce backend précis.
