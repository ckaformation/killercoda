# Scénario Killercoda — Troubleshooting NetworkPolicy

## Contenu

```
netpol-troubleshooting/
├── index.json
├── intro.md
├── intro-background.sh     # namespaces a/b/c/d, 5 pods, 2 NetworkPolicy cassées
├── step1.md / step1-verify.sh   # cas 1 : matchLabels erroné (a -> b)
├── step2.md / step2-verify.sh   # cas 2 : ET au lieu de OU (c/d)
└── finish.md
```

## Choix effectués et pourquoi — le point le plus incertain

**Boutons "Tip" et "Solution" implémentés en HTML `<details>/<summary>`**,
demandé explicitement. Je n'ai trouvé **aucune documentation
spécifique à Killercoda** confirmant que son moteur de rendu Markdown
laisse passer du HTML brut. `<details>/<summary>` est le standard
quasi universel pour ce genre de contenu repliable (GitHub, GitLab, la
plupart des générateurs de sites statiques), donc c'est le choix le
mieux justifié dont je dispose — mais je ne peux pas garantir qu'il
s'affichera correctement sur Killercoda tant que ce n'est pas testé.
**À vérifier en priorité absolue lors du premier test réel.** Si ça ne
fonctionne pas, la solution de repli la plus simple serait de déplacer
le contenu "Tip"/"Solution" dans des fichiers séparés, révélés
seulement en donnant leur chemin à l'élève (moins élégant, mais
garanti fonctionner avec le Markdown déjà confirmé ailleurs dans ce
cursus).

## Autres choix

- **Namespaces nommés littéralement `a`, `b`, `c`, `d`**, reprenant
  exactement le vocabulaire de la demande, plutôt qu'un thème Star
  Wars pour les namespaces eux-mêmes : dans un exercice de
  troubleshooting, la correspondance directe avec l'énoncé prime sur
  la thématisation. Les pods, en revanche, restent à thème
  (`han`/`chewie`, `lando`/`wedge`/`biggs`), cohérent avec le reste du
  cursus.

- **Backend `kubernetes-kubeadm-1node` utilisé tel quel** (CNI Cilium
  natif, confirmé par toi dans `netpol-isolation`) : script `background`
  léger, sans reset ni réinstallation, cohérent avec le retour en
  arrière déjà effectué sur `netpol-isolation`.

- **Bug 1 (étape 1) : valeur de label erronée sur un `namespaceSelector`
  seul** (`project: beta` au lieu de `project: alpha`), volontairement
  simple : un seul sélecteur en cause, pour une première prise en main
  du diagnostic avant la complexité de l'étape 2.

- **Bug 2 (étape 2) : double panne cumulée**, demandée explicitement
  ("une règle AND et un mauvais podSelector matchlabel") — `ET` au
  lieu de `OU` (namespaceSelector et podSelector combinés dans le même
  élément de liste), **et** une valeur de `podSelector` erronée
  (`squad: empire` au lieu de `squad: rebel`). Corriger un seul des
  deux ne suffit pas : soit la syntaxe reste en ET (donc rien ne
  correspond jamais, même avec la bonne valeur), soit la valeur reste
  fausse (donc le OU fonctionnerait pour `c` mais pas pour le trafic
  interne à `d`).

- **`ports: [{protocol: TCP, port: 80}]` explicite sur la policy de
  l'étape 2**, demandé explicitement ("sur le port 80") — absent de la
  policy de l'étape 1, qui n'a pas cette exigence dans la demande.

- **`kubernetes.io/metadata.name: c` pour le `namespaceSelector` de
  l'étape 2** (label posé automatiquement par l'API server depuis
  Kubernetes 1.21), plutôt qu'un label custom sur `c` : évite d'avoir à
  labelliser `c` manuellement, cohérent avec `netpol-isolation`.

- **Tous les pods sous `nginx:alpine` + `curl` installé au démarrage**,
  comme dans `netpol-isolation` : chacun doit pouvoir être à la fois
  source et cible selon le test (notamment `wedge`, testé comme cible
  depuis `lando` puis comme source vers `biggs`).

- **`verify.sh` teste uniquement le résultat fonctionnel (curl qui
  passe), jamais la syntaxe exacte de la correction** : l'élève est
  libre de corriger la `NetworkPolicy` existante par n'importe quel
  moyen (édition, remplacement complet, etc.), du moment que le
  comportement attendu est atteint.

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/services-networking/network-policies/

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- **Rendu des balises `<details>/<summary>` non vérifié sur
  Killercoda** — voir la section dédiée ci-dessus, c'est le point
  numéro un à valider.
- `apk add --no-cache curl` au démarrage de chaque pod suppose un accès
  sortant à internet au moment de leur création (avant toute
  NetworkPolicy) — cohérent avec `netpol-isolation`, mêmes réserves.
