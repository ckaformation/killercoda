# Scénario Killercoda — Taints et Tolerations

## Contenu

```
taints-tolerations/
├── index.json
├── intro.md
├── intro-background.sh     # taint control-plane retiré, 2 deployments sans toleration
├── step1.md / step1-verify.sh   # taint NoSchedule + rollout restart (baseline)
├── step2.md / step2-verify.sh   # toleration NoSchedule sur millennium-falcon
├── step3.md / step3-verify.sh   # taint NoExecute + éviction observée
├── step4.md / step4-verify.sh   # toleration NoExecute sur millennium-falcon
└── finish.md
```

## Choix effectués et pourquoi

- **Découpage en 4 étapes Killercoda**, cohérent avec la granularité déjà
  adoptée dans `node-selector-scheduling` : chaque ajout de taint et
  chaque ajout de toleration constituent des points de contrôle
  distincts et vérifiables séparément.

- **Retrait explicite du taint control-plane par défaut**, comme dans
  `node-selector-scheduling` et pour la même raison : sans ça, les deux
  Deployments seraient déjà bloqués sur `controlplane` avant même que
  l'élève n'ajoute ses propres taints, ce qui casserait la
  démonstration "avant/après" voulue par ce scénario.

- **`rollout restart` des deux Deployments à l'étape 1**, avant toute
  toleration : établit une base de comparaison propre et déterministe
  (les 4 pods forcément sur `node01`), plutôt que de dépendre du
  placement initial aléatoire des pods créés avant l'existence du
  taint. Sans cette étape, un pod déjà présent sur `controlplane` au
  moment de l'ajout du taint y serait resté (`NoSchedule` n'évince
  rien), ce qui aurait rendu le point de départ imprévisible.

- **Deux clés de taint distinctes** (`empire` pour `NoSchedule`,
  `order66` pour `NoExecute`), plutôt qu'une seule clé réutilisée avec
  un effet différent : la demande parle d'une "nouvelle taint
  supplémentaire", et un nœud peut effectivement porter plusieurs
  taints simultanément — ça permet aussi de montrer explicitement
  qu'une toleration ne couvre qu'un seul taint (clé+valeur+effet),
  jamais "tous les taints du nœud".

- **Vérification non déterministe assumée pour le placement de
  `millennium-falcon` sur `controlplane`** (étapes 2 et 4) : une fois
  qu'il tolère le(s) taint(s) de `controlplane`, rien ne garantit
  formellement que le scheduler y place effectivement un pod plutôt que
  de tout laisser sur `node01` — les deux nœuds deviennent simplement
  "éligibles", sans préférence explicite. En pratique, l'équilibrage de
  charge par défaut du scheduler rend un placement sur `controlplane`
  hautement probable (`node01` héberge alors plus de pods), mais pas
  strictement garanti. `step2-verify.sh`/`step4-verify.sh` en tiennent
  compte : en l'absence de pod sur `controlplane`, ils invitent à
  relancer la vérification plutôt que d'échouer platement, sans pour
  autant réessayer indéfiniment en boucle côté script.

- **Vérification de l'éviction (étape 3) en revanche pleinement
  déterministe** : `NoExecute` expulse activement les pods qui ne le
  tolèrent pas, donc `step3-verify.sh` peut affirmer sans ambiguïté que
  plus aucun pod `millennium-falcon` ne doit rester sur `controlplane`
  après ce taint — contrairement au placement "positif" des étapes 2/4.

- **`x-wing-squadron` jamais modifié**, demandé explicitement : sert de
  témoin tout au long du scénario, ses pods doivent rester sur `node01`
  du début à la fin, quoi qu'il arrive à `controlplane`.

- **Noms à thème Star Wars** (`millennium-falcon` : vaisseau aux accès
  privilégiés, cohérent avec le fait qu'on lui ajoute des tolerations ;
  `x-wing-squadron` : chasseurs rebelles standards, sans accès
  particulier ; taints `empire=occupied`/`order66=active`, ce dernier
  étant une référence directe à l'Ordre 66, l'événement Star Wars
  déclenchant l'élimination des Jedi — un clin d'œil volontaire pour un
  taint `NoExecute`), conformément à la préférence indiquée pour ce
  cursus.

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Comme indiqué plus haut, le placement effectif de `millennium-falcon`
  sur `controlplane` aux étapes 2 et 4 repose sur le comportement par
  défaut du scheduler (équilibrage de charge), pas sur une garantie
  stricte de l'API Kubernetes — à surveiller en priorité si les
  vérifications se montrent capricieuses en conditions réelles.
