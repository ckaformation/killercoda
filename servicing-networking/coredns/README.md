# Scénario Killercoda — CoreDNS troubleshooting & découverte de service

## Contenu

```
coredns-troubleshoot/
├── index.json
├── intro.md
├── intro-background.sh   # casse coredns + déploie l'app pré-existante (death-star)
├── step1.md / step1-verify.sh   # troubleshoot CoreDNS (évasif + indices en dropdown)
└── step2.md / step2-verify.sh   # Deployment + Service + découverte de service inter-namespace
└── finish.md
```

## Choix effectués et pourquoi

- **Backend `kubernetes-kubeadm-1node`** : un cluster single-node
  standard suffit, pas besoin de composant réseau additionnel pour ce
  scénario.

- **Directive Corefile cassée : `holocron`** (référence Star Wars, un
  artefact de stockage de savoir — cohérent avec le thème du cursus).
  Injectée en tête du bloc serveur (`.:53 {`) du `Corefile`, quel que
  soit le reste de son contenu. C'est une directive que CoreDNS ne
  reconnaît pas : l'analyse du `Corefile` échoue au démarrage, le
  process quitte immédiatement, d'où le `CrashLoopBackOff`.

- **Injection dynamique plutôt qu'un `Corefile` réécrit en dur** :
  `intro-background.sh` lit le `Corefile` réellement présent sur le
  cluster (`kubectl get configmap coredns -o jsonpath=...`) puis y
  insère la ligne fautive, au lieu d'écraser le ConfigMap avec un
  contenu supposé. Ça évite de me baser sur un contenu par défaut que
  je n'ai pas pu vérifier pour la version exacte de kubeadm utilisée
  par ce backend Killercoda.

- **`rollout restart` explicite après l'édition du ConfigMap** : le
  plugin `reload` de CoreDNS (présent par défaut dans le Corefile
  kubeadm) surveille le fichier et tente un rechargement à chaud, mais
  s'il échoue à parser la nouvelle version, il **conserve l'ancienne
  configuration en mémoire sans planter le process** — le
  `CrashLoopBackOff` ne surviendrait donc pas sans un redémarrage
  forcé des pods, qui eux relisent le `Corefile` en entier à froid.
  Cette mécanique (reload gracieux qui n'aurait pas suffi) n'a pas été
  testée en conditions réelles sur Killercoda — à confirmer sur le
  premier run.

- **Deux indices en menu dépliant (`<details><summary>`)** plutôt
  qu'affichés directement : syntaxe HTML standard, vue fonctionner
  dans au moins un scénario Killercoda existant consulté en ligne. Pas
  de confirmation officielle de la documentation Killercoda elle-même
  (je n'ai pas trouvé de page de référence dédiée) — à vérifier
  visuellement au premier rendu du scénario.

- **Étape 1 volontairement évasive** (titre "Quelque chose ne tourne
  pas rond", pas de mention de CoreDNS ni de ConfigMap dans le corps
  du texte avant les indices) : l'élève découvre lui-même, via
  `kubectl get pods -A`, que ce sont les pods `coredns` qui sont en
  `CrashLoopBackOff` — c'est une observation directe et normale du
  troubleshooting, pas un indice à cacher. Ce qui reste caché, ce sont
  la cause exacte (le ConfigMap) et le nom de la directive fautive.

- **Application pré-existante `death-star/sensor-array`** : deux
  conteneurs dans le même pod plutôt qu'un seul, pour respecter à la
  fois la contrainte "même image que celle créée par l'élève"
  (conteneur `sensor-array`, `nginx:1-alpine`) et le besoin d'un
  mécanisme de sonde observable dans les logs (conteneur sidecar
  `probe-droid`, `busybox:1.36`, boucle `wget` sur `$TARGET_URL`
  toutes les 5s). `nginx:1-alpine` seul n'aurait rien loggé
  spontanément qui permette de vérifier la connectivité vers le
  service créé par l'élève.

- **`kubectl set env deployment/... -c probe-droid TARGET_URL=...`**
  suggéré dans `step2.md` : déclenche un rollout du déploiement
  pré-existant, donc un nouveau pod qui démarre directement avec la
  bonne valeur (pas de dépendance à un hot-reload d'env var, qui
  n'existe pas nativement pour les variables d'environnement d'un pod
  déjà démarré).

- **Vérification dynamique côté élève (étape 2)** : `step2-verify.sh`
  ne suppose aucun nom fixe pour le namespace/Deployment/Service créés
  par l'élève — il les recherche par caractéristiques (image
  `nginx:1-alpine`, Service `ClusterIP` port `80`) parmi les
  namespaces hors système et hors `death-star`, dans le même esprit
  que les scénarios précédents.

## Sources utilisées

- Comportement de CoreDNS (échec de parsing du `Corefile` = process
  qui quitte au démarrage, plugin `reload` qui ne plante pas sur un
  Corefile invalide) : connaissance générale CoreDNS/Kubernetes, non
  re-vérifiée via une recherche dédiée pour cette conversation — à
  confirmer si le comportement observé diffère en pratique.
- Résolution DNS courte inter-namespace (`<service>.<namespace>` via
  expansion des domaines de recherche `resolv.conf`) : connaissance
  générale Kubernetes.
- Syntaxe `<details><summary>` dans un scénario Killercoda : repérée
  dans un dépôt GitHub tiers de scénarios Killercoda
  (`DevOps-learninig-org/killerkoda-DevOps-practice`), pas dans une
  doc officielle Killercoda.

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents.
- Le mécanisme du plugin `reload` de CoreDNS (reload gracieux qui
  échoue silencieusement sur Corefile invalide, sans crash) est une
  connaissance générale non re-vérifiée spécifiquement pour cette
  conversation — c'est ce qui justifie le `rollout restart` explicite
  dans `intro-background.sh`, mais si le comportement réel diffère
  (par exemple si CoreDNS venait à planter directement sur reload
  raté), le `rollout restart` reste de toute façon inoffensif.
- Rendu visuel des menus dépliants (`<details>`) non vérifié
  directement sur Killercoda.
- `nslookup` dans l'image `busybox:1.36` utilisée pour le test
  fonctionnel de `step1-verify.sh` : comportement standard attendu
  (sortie contenant `Name:` et le FQDN résolu), non re-vérifié pour
  cette version précise de l'image.
