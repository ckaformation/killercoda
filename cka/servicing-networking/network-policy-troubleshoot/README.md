# Scénario Killercoda — Troubleshooting NetworkPolicy

## Contenu

```
netpol-troubleshooting/
├── index.json
├── intro.md
├── intro-background.sh     # namespaces dagobah/endor/kamino/mustafar, 5 pods, 2 NetworkPolicy cassées
├── step1.md / step1-verify.sh   # cas 1 : matchLabels erroné (dagobah -> endor)
├── step2.md / step2-verify.sh   # cas 2 : ET au lieu de OU (kamino/mustafar)
└── finish.md
```

## Corrections apportées suite au premier retour de test

- **Confirmé fonctionnel** : les boutons Tip/Solution en `<details>/<summary>`
  s'affichent correctement sur Killercoda.

- **Namespaces renommés** (`a`/`b`/`c`/`d` → `dagobah`/`endor`/`kamino`/`mustafar`) :
  les lettres d'origine dans la demande étaient des exemples de
  vocabulaire, pas des noms à reprendre littéralement — corrigé avec
  des noms à thème Star Wars, cohérents avec le reste du cursus.

- **Titres et description neutralisés** (`index.json`, titres de
  `step1.md`/`step2.md`) : les versions précédentes révélaient la
  nature du bug avant même que l'élève ne commence à chercher
  ("matchLabels erroné", "logique ET au lieu de OU" apparaissaient
  dans les titres visibles dès la liste des étapes). Les titres ne
  décrivent plus que le **symptôme** ("han ne parvient pas à joindre
  chewie", "communications bloquées dans mustafar"), jamais la cause.

- **Cas 2 : suppression du second bug (mauvaise valeur de
  `podSelector`).** Erreur de conception initiale : j'avais combiné
  deux fautes (ET au lieu de OU, **et** une valeur de label erronée),
  ce qui n'était pas demandé et diluait l'essence de l'exercice. Le
  `podSelector.matchLabels: squad: rebel` est maintenant **la bonne
  valeur dès le départ** (`wedge` et `biggs` portent réellement ce
  label) : le seul problème restant est la combinaison en ET plutôt
  qu'en OU. L'élève doit constater que le label est correct — pour
  mieux comprendre que le problème est ailleurs, dans la structure YAML
  elle-même, pas dans les valeurs.

## Autres choix (inchangés depuis la version précédente)

- **Backend `kubernetes-kubeadm-1node` utilisé tel quel** (CNI Cilium
  natif, confirmé dans `netpol-isolation`).

- **`ports: [{protocol: TCP, port: 80}]` explicite sur la policy du cas
  2**, demandé explicitement.

- **`kubernetes.io/metadata.name: kamino`** pour le `namespaceSelector`
  du cas 2 (label posé automatiquement par l'API server), plutôt qu'un
  label custom à poser sur `kamino`.

- **Tous les pods sous `nginx:alpine` + `curl` installé au démarrage** :
  chacun doit pouvoir être à la fois source et cible selon le test.

- **`verify.sh` teste uniquement le résultat fonctionnel**, jamais la
  syntaxe exacte de la correction.

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/services-networking/network-policies/

## Limites connues

- Testé uniquement "sur le papier" pour cette itération : le rendu des
  boutons Tip/Solution est confirmé fonctionnel (retour direct), mais
  le reste du scénario (namespaces renommés, bug du cas 2 simplifié)
  n'a pas encore été retesté en conditions réelles.
- `apk add --no-cache curl` au démarrage de chaque pod suppose un accès
  sortant à internet au moment de leur création — cohérent avec
  `netpol-isolation`, mêmes réserves.
