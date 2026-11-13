# Scénario Killercoda — NetworkPolicy : isolation par défaut et exceptions ciblées

## Contenu

```
netpol-isolation/
├── index.json
├── intro.md
├── intro-background.sh     # alias k, namespaces tatooine/alderaan, pods luke/obi-wan/leia
├── step1.md / step1-verify.sh   # deny by default dans tatooine et alderaan
├── step2.md / step2-verify.sh   # allow luke -> obi-wan (intra-ns)
├── step3.md / step3-verify.sh   # allow luke -> leia (inter-ns), piège AND/OR
└── finish.md
```

## Choix effectués et pourquoi

- **Backend `kubernetes-kubeadm-1node` utilisé tel quel, sans reset ni
  réinstallation.** Confirmé : son CNI natif est **Cilium**, qui
  implémente les `NetworkPolicy` standard — l'incertitude qui m'avait
  fait reconstruire tout le cluster avec Calico dans une version
  précédente de ce scénario n'a plus lieu d'être. Retour à un script
  `background` léger, cohérent avec les autres scénarios mono-nœud
  "légers" de ce cursus (`rbac-luke-jedi`, `operator-crd-greeting`...).

- **Pas de `wait-for-prep.sh`** : ce mécanisme (utilisé dans
  `2nodes-cluster-creation`/`kubeadm-cluster-upgrade`/`netpol-isolation`
  v1) se justifiait par un script `background` très long (reset complet
  + réinstallation + `kubeadm init` + Calico). La préparation actuelle
  (2 namespaces + 3 pods) est d'un ordre de grandeur comparable aux
  autres scénarios mono-nœud légers du cursus, qui n'en ont jamais eu
  besoin.

- **Pas de retrait explicite de taint** : `kubernetes-kubeadm-1node`
  est déjà documenté comme livré taint retiré nativement — cohérent
  avec les autres scénarios utilisant ce même backend sans y toucher
  (`rbac-luke-jedi`, `rbac-cronjob-nettoyeur`).

- **`luke` et `obi-wan` tournent tous deux sous `nginx:alpine` avec
  `curl` installé au démarrage** (`apk add --no-cache curl && nginx -g
  'daemon off;'`) : inchangé par rapport à la version précédente —
  l'étape 3 a toujours besoin que les deux puissent à la fois servir
  une page web et lancer eux-mêmes des `curl`.

- **`policyTypes: [Ingress]` uniquement, pas `Egress`** : toujours pour
  garder l'exercice concentré sur ce qui est testé (l'entrant vers
  `obi-wan`/`leia`), sans ajouter un second axe de blocage.

- **`kubernetes.io/metadata.name` pour cibler `tatooine`** (étape 3) :
  toujours le label posé automatiquement par l'API server sur tout
  namespace, sans avoir à en poser un à la main.

- **Démonstration explicite du piège AND/OR** (étape 3), inchangée :
  les deux versions de la policy sont montrées côte à côte, et la
  vérification teste positivement `luke` et négativement `obi-wan`
  contre `leia`.

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/services-networking/network-policies/

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le support des `NetworkPolicy` par Cilium sur ce backend précis est
  confirmé par toi (l'utilisateur), pas vérifié indépendamment par mes
  soins — je m'appuie sur cette confirmation plutôt que sur une
  recherche documentaire, Cilium étant de toute façon un CNI largement
  reconnu pour son support complet des NetworkPolicy standard.
- `apk add --no-cache curl` au démarrage des pods `luke` et `obi-wan`
  suppose un accès sortant à internet fonctionnel au moment de leur
  création (avant que les NetworkPolicy ne soient posées) — cohérent
  avec le reste du cursus, mais pas vérifié spécifiquement ici.
