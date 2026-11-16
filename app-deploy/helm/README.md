# Scénario Killercoda — Cycle de vie Helm (install/upgrade/rollback)

## Contenu

```
helm-lifecycle/
├── index.json
├── intro.md
├── intro-background.sh   # installe Helm si absent + repos + release falco préexistante
├── step1.md / step1-verify.sh   # install podinfo
├── step2.md / step2-verify.sh   # upgrade falco (log_level debug)
└── step3.md / step3-verify.sh   # rollback falco (retour à warning)
└── finish.md
```

## Choix effectués et pourquoi

- **Helm installé conditionnellement** (`command -v helm` avant
  d'installer) : pas de confirmation qu'il est préinstallé sur ce
  backend (contrairement à `local-path-provisioner` sur le backend 2
  nœuds, dont c'est confirmé) — installation via le script officiel
  `get-helm-3`, idempotente si déjà présent.
- **`podinfo` : repo ajouté sous l'alias `podinfo`**
  (`https://stefanprodan.github.io/podinfo`), pour que la référence
  `podinfo/podinfo` demandée fonctionne telle quelle — l'alias n'est
  pas imposé par le chart, seulement par la commande `helm repo add`.
- **`ui.message`** confirmé comme clé réelle et actuelle du
  `values.yaml` officiel du chart `podinfo` (dépôt GitHub
  `stefanprodan/podinfo`, fichier `charts/podinfo/values.yaml`).
- **`falco.log_level`** confirmé comme chemin de configuration valide
  sur des exemples récents (2026) d'installation Helm de Falco,
  cohérent avec le schéma "snake_case" de la version actuelle du
  chart (les très anciennes versions utilisaient un schéma
  différent, en camelCase).
- **`--set driver.kind=modern_ebpf`** ajouté à l'installation initiale
  de falco (absent de la demande) : évite de dépendre d'un module
  noyau précompilé pour le kernel exact de ce backend Killercoda,
  inconnu à l'avance — augmente les chances que le pod falco démarre
  réellement, sans que ce soit requis pour la réussite de l'exercice
  (voir point suivant).
- **Aucune commande Helm de ce scénario n'utilise `--wait`** :
  volontaire. Falco nécessite un support eBPF/noyau pour fonctionner
  pleinement, ce qui n'est pas garanti sur ce backend. Sans `--wait`,
  `helm install`/`upgrade`/`rollback` réussissent indépendamment de
  l'état réel des pods falco — l'exercice porte sur le cycle de vie
  Helm, pas sur la supervision runtime de Falco.
- **`step2.md` suit la commande exacte demandée** (`--set
  falco.log_level=debug`, sans `--reuse-values`) plutôt que de la
  "corriger" silencieusement : la conséquence (réinitialisation de
  `driver.kind` aux valeurs par défaut du chart) est documentée
  explicitement dans `finish.md` comme point pédagogique, plutôt que
  masquée.
- **`step3-verify.sh` vérifie le contenu des values, pas le numéro de
  révision "1"** : `helm rollback` crée une nouvelle révision
  (ici la 3) avec le contenu de la révision cible, il ne réécrit pas
  l'historique — vérifier le numéro littéral "1" aurait été une
  erreur.
- **Vérifications basées sur `grep` simple sur la sortie YAML de
  `helm get values`**, plutôt que sur `-o json` + `jq`/`python3` :
  évite une dépendance à un outil dont la disponibilité n'est pas
  confirmée sur ce backend.
- **Pas de thème Star Wars** pour les noms de namespace/release
  (`podinfo`, `falco`) : nommer autrement des charts tiers largement
  connus par leur vrai nom aurait nui à la clarté sans bénéfice
  pédagogique.

## Sources utilisées

- **`ui.message` (podinfo) vérifié directement** en récupérant le
  `values.yaml` réel du chart depuis
  `raw.githubusercontent.com/stefanprodan/podinfo/master/charts/podinfo/values.yaml` :
  confirme `ui: { color, message: "", logo }`.
- **`falco.log_level` (falco) vérifié directement** en récupérant le
  `values.yaml` réel du chart depuis
  `raw.githubusercontent.com/falcosecurity/charts/master/charts/falco/values.yaml` :
  confirme la clé racine `falco:` (ligne 700) contenant `log_level:
  info` par défaut (ligne 1339), avec la liste exacte des niveaux
  valides documentée en commentaire : `emergency, alert, critical,
  error, warning, notice, info, debug` — `warning` et `debug` en font
  bien partie.
- Dépôt Helm `podinfo` (`https://stefanprodan.github.io/podinfo`) et
  `falcosecurity` (`https://falcosecurity.github.io/charts`) :
  confirmés par de multiples sources indépendantes et cohérentes
  (doc officielle Falco, Artifact Hub, dépôt GitHub officiel
  podinfo).
- **`driver.kind=modern_ebpf`** comme option valide d'installation :
  confirmé par la doc officielle Falco
  (`falco.org/docs/getting-started/learning-environments`).
- Comportement de `helm rollback` (nouvelle révision, pas de
  réécriture d'historique) et de `helm upgrade --set` sans
  `--reuse-values` (retour aux défauts du chart) : connaissance
  générale Helm, non re-vérifiée par recherche dédiée dans cette
  conversation.

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents.
- **Le pod falco pourrait ne jamais devenir Running/Ready** sur ce
  backend, faute de support eBPF/noyau adapté — n'affecte pas la
  réussite de l'exercice (voir choix ci-dessus), mais peut surprendre
  visuellement si l'élève inspecte `kubectl get pods -n falco`.
- **Nom exact de l'objet `Deployment` créé par le chart podinfo**
  (`kubectl rollout status deployment/podinfo` dans
  `step1-verify.sh`) : très probable vu la convention de nommage
  Helm standard (`{{ .Release.Name }}`), mais non confirmé ligne à
  ligne dans les templates du chart.
- **Schéma exact des valeurs du chart `falcosecurity/falco`** pour la
  version qui sera réellement résolue par `helm repo add` +
  `helm install` au moment du test (dépôt non versionné explicitement
  dans les commandes) : les sources consultées sont datées de fin
  2025/début 2026 et cohérentes entre elles sur `falco.log_level`,
  mais la version exacte du chart installée dépendra de ce qui est
  publié au moment du test réel.
