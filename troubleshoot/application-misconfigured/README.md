# Scénario Killercoda — Troubleshooting déploiements applicatifs (3 pannes)

## Contenu

```
pod-scheduling-config-troubleshoot/
├── index.json
├── intro.md
├── intro-background.sh   # 3 namespaces + 3 deployments (chacun avec sa panne)
├── step1.md / step1-verify.sh   # jedi-temple — mauvais ConfigMap
├── step2.md / step2-verify.sh   # outer-rim — nodeName inexistant
└── step3.md / step3-verify.sh   # endor — serviceAccount inexistant
└── finish.md
```

## Choix effectués et pourquoi

- **Namespaces/déploiements** : `jedi-temple`/`archive-terminal`
  (archives = ConfigMap), `outer-rim`/`long-range-probe` (sonde
  envoyée nulle part = nœud inexistant), `endor`/`ewok-patrol`
  (contrôle d'identité = ServiceAccount). Noms distincts de ceux déjà
  utilisés dans d'autres scénarios de ce cursus.
- **`archive-config-old` vs `archive-config`** : le ConfigMap réel
  existe sous un nom légèrement différent de celui référencé par le
  déploiement, plutôt qu'une référence à un nom totalement
  aléatoire — plus réaliste (ressemble à un renommage oublié).
- **`nodeName` (pas `nodeSelector`)** pour la panne 2, conformément à
  la demande : ce champ court-circuite entièrement le scheduler
  (contrairement à `nodeSelector`, qui laisserait au moins une trace
  d'échec de planification côté scheduler) — le pod reste `Pending`
  sans aucun événement de scheduling, symptôme assez différent des
  deux autres pannes.
- **`serviceAccountName: default`** comme correction suggérée pour la
  panne 3 : le ServiceAccount `default` existe toujours dans tout
  namespace Kubernetes, donc toujours une correction valide sans
  dépendre d'un ServiceAccount spécifique à créer.
- **Les 3 vérifications utilisent `kubectl rollout status`** comme
  critère final commun (Running/Ready), malgré des mécanismes de
  panne différents (`CreateContainerConfigError`, pod jamais planifié,
  échec de création de pod) : ce critère fonctionne correctement dans
  les 3 cas, sans avoir besoin de coder une détection différente par
  type de panne.
- **Textes des 3 étapes volontairement génériques** ("ne fonctionne
  pas correctement, diagnostique et corrige"), conformément à la
  demande — la nature exacte de chaque panne n'apparaît que dans les
  dropdowns indice/solution.

## Sources utilisées

- Comportement de `CreateContainerConfigError` sur une référence
  `configMapKeyRef` invalide, comportement de `nodeName` (bypass du
  scheduler), et rejet de création de pod sur un
  `serviceAccountName` inexistant (admission controller
  `ServiceAccount`) : connaissance générale Kubernetes, non
  re-vérifiée par recherche dédiée dans cette conversation.

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents.
- **Mécanisme exact de blocage pour la panne 3** (ServiceAccount
  inexistant) : je pars du principe que l'admission controller
  `ServiceAccount` bloque la création du pod à la source (aucun objet
  Pod ne serait alors créé, l'erreur apparaissant sur le ReplicaSet/
  Deployment) — mais si cette validation n'est pas activée sur ce
  cluster, le comportement réel pourrait différer (pod créé mais
  bloqué autrement, par exemple à l'étape de montage du token). Dans
  les deux cas, `step3-verify.sh` reste valable puisqu'il se base sur
  `rollout status`, indépendant du mécanisme exact de blocage.
- **Absence de taint sur `controlplane` empêchant la planification
  normale** : je pars du principe, comme pour les scénarios single-
  node précédents, que ce backend permet la planification de charges
  de travail ordinaires sans taint bloquant — cohérent avec tous les
  scénarios précédents sur ce même backend.
