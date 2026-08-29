# Scénario Killercoda — NetworkPolicy : isolation par défaut et exceptions ciblées

## Contenu

```
netpol-isolation/
├── index.json
├── intro.md
├── intro-background.sh     # reconstruction complète du cluster (Calico) + namespaces/pods
├── step1.md / step1-verify.sh   # deny by default dans tatooine et alderaan
├── step2.md / step2-verify.sh   # allow luke -> obi-wan (intra-ns)
├── step3.md / step3-verify.sh   # allow luke -> leia (inter-ns), piège AND/OR
└── finish.md
```

## Choix effectués et pourquoi

- **Cluster entièrement reconstruit (kubeadm reset + réinstallation +
  kubeadm init + Calico), plutôt que le backend utilisé "tel quel"**
  (contrairement à la plupart des scénarios de `workloads-scheduling`,
  comme `static-pods` ou `kubeadm-certs-management`). Ce scénario
  repose intégralement sur l'application réelle des `NetworkPolicy`,
  qui dépend entièrement du CNI installé — tous ne les implémentent
  pas (Flannel seul, notamment, les ignore silencieusement). N'ayant
  aucune confirmation du CNI natif de ce backend Killercoda, je ne
  pouvais pas prendre le risque qu'un CNI non conforme rende tout
  l'exercice muet (les commandes s'exécuteraient sans erreur, mais
  rien ne serait jamais bloqué). Le même raisonnement m'avait déjà fait
  choisir cette approche pour `2nodes-cluster-creation`, dont je
  reprends directement le script d'installation.

- **Backend `kubernetes-kubeadm-1node`** malgré la reconstruction
  complète : un seul nœud suffit, les `NetworkPolicy` opèrent au niveau
  pod/namespace, pas au niveau nœud — pas besoin de la complexité
  supplémentaire d'un second nœud ici.

- **Mécanisme `wait-for-prep.sh`** repris de `2nodes-cluster-creation`
  et `kubeadm-cluster-upgrade` : la préparation ici est particulièrement
  lourde (reset, réinstallation, `kubeadm init`, Calico, création des
  namespaces et des 3 pods), donc le risque de course avec un·e élève
  rapide est réel — timeout porté à 300s en conséquence.

- **`luke` et `obi-wan` tournent tous deux sous `nginx:alpine` avec
  `curl` installé au démarrage** (`apk add --no-cache curl && nginx -g
  'daemon off;'`), plutôt qu'une image dédiée comme `curlimages/curl` :
  l'étape 3 a besoin que les **deux** puissent à la fois servir une
  page web (tests des étapes 1-2, où l'un est la cible de l'autre) et
  lancer eux-mêmes des `curl` (étape 3, où on doit prouver que `luke`
  passe et `obi-wan` non). Aucune image seule du marché ne couvrait
  spontanément les deux usages en même temps.

- **`policyTypes: [Ingress]` uniquement**, pas `Egress`, sur les
  policies de deny par défaut : la demande ne précise pas de direction,
  et se limiter à l'Ingress garde l'exercice concentré sur ce qui est
  testé (l'accès entrant vers `obi-wan` et `leia`) sans ajouter un
  second axe de blocage (l'`Egress` de `luke`) qui aurait compliqué le
  diagnostic sans bénéfice pédagogique supplémentaire ici.

- **`kubernetes.io/metadata.name` pour cibler `tatooine` dans le
  `namespaceSelector`** (étape 3) : label posé automatiquement par
  l'API server sur tout namespace depuis Kubernetes 1.21, sans avoir à
  labelliser `tatooine` manuellement au préalable — pratique standard
  actuelle pour ce genre de sélection.

- **Démonstration explicite et volontaire du piège AND/OR** (étape 3),
  demandée explicitement : les deux versions de la policy (correcte et
  incorrecte) sont montrées côte à côte dans `step3.md`, et la
  vérification teste positivement `luke` **et** négativement `obi-wan`
  contre `leia` — la seule façon de prouver que la version choisie
  est bien la version ET, pas la version OU (les deux laisseraient
  passer `luke`, seule la version ET bloque `obi-wan`).

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/services-networking/network-policies/

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le script `background` est le plus long de tout le cursus à ce
  stade (reset complet + réinstallation + init + Calico + 3 pods) ; le
  timeout de 300s dans `wait-for-prep.sh` est une estimation prudente,
  pas une mesure réelle sur ce backend.
- `apk add --no-cache curl` au démarrage des pods `luke` et `obi-wan`
  suppose un accès sortant à internet fonctionnel au moment de leur
  création (avant que les NetworkPolicy ne soient posées, donc sans
  restriction à ce stade) — cohérent avec le reste du cursus qui
  dépend déjà d'un accès internet pour récupérer des images, mais pas
  vérifié spécifiquement pour cette commande sur ce backend.
