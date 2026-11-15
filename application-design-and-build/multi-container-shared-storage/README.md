# Scénario Killercoda — Multi-container pods et stockage partagé

## Contenu

```
multi-container-shared-storage/
├── index.json                   # backend kubernetes-kubeadm-1node, 3 étapes
├── intro.md                     # 3 Deployments, PVC holocron, ce que l'élève va faire
├── intro-background.sh          # alias k, /root/<deployment>.yaml, PV hostPath + PVC holocron, 3 Deployments
├── step1.md / step1-verify.sh   # dagobah : init container busybox (yoda) + emptyDir
├── step2.md / step2-verify.sh   # x-wing : sidecar natif busybox (r2-d2, restartPolicy: Always) + emptyDir
├── step3.md / step3-verify.sh   # jedi-archives : PVC holocron monté sous /usr/share/nginx/html
└── finish.md
```

## Choix effectués et pourquoi

- **Emplacement** : le chemin demandé était `application-design-and-design`, qui n'existe pas. J'ai supposé une coquille pour le cours existant `application-design-and-build` (CKAD - Design & build). Aucun nouveau cours, donc pas de modification de `structure.json`.
- **Noms** : Deployments `dagobah` (Yoda prépare avant la mission : init container `yoda`), `x-wing` (R2-D2 accompagne le pilote pendant tout le vol : sidecar `r2-d2`), `jedi-archives` (PVC `holocron`, PV `holocron-pv`). Les noms des Deployments, du PVC et du PV sont imposés par les vérifications ; les noms des containers et du volume (`html`) ne le sont pas.
- **Manifests de départ** : `/root/dagobah.yaml`, `/root/x-wing.yaml`, `/root/jedi-archives.yaml`, identiques sauf `name`, `labels.app` et `selector.matchLabels`. `nginx:alpine`, 1 réplica, `terminationGracePeriodSeconds: 1`. Ils sont écrits au tout début du script, avant l'attente de l'API, pour être lisibles dès l'ouverture du scénario.
- **`terminationGracePeriodSeconds: 1`** : l'ancien pod disparaît vite après chaque `k apply`, donc `items[0]` du `jsonpath` désigne presque toujours le nouveau pod. C'est utile en particulier à l'étape 2 : la boucle `while` du sidecar, PID 1 de son container, ne réagit pas à SIGTERM et serait sinon tuée au bout de 30 s seulement.
- **PVC sans provisionneur** : `local-path-provisioner` n'est pas installé sur `kubernetes-kubeadm-1node`. Le script crée donc un PV `hostPath` (`/data/holocron`, 100Mi, `ReadWriteOnce`, `Retain`) et un PVC `holocron` avec `storageClassName: ""` des deux côtés et `volumeName: holocron-pv` pour un lien direct et déterministe. La page `index.html` est écrite sur le nœud avant la création du PV, donc le PVC « contient » déjà la page.
- **Rien n'est monté avant l'étape 3** : le PVC reste `Bound` sans être utilisé.
- **Test par l'IP du pod, sans Service** : `IP=$(k get pod -l app=… -o jsonpath='{.items[0].status.podIP}')` puis `curl -s $IP`. Une commande par bloc `{{exec}}`, aucun champ à compléter. La variable `IP` reste définie entre deux clics car les commandes s'exécutent dans le même terminal.
- **Étape 1, état avant/après** : un premier `curl` montre la page par défaut de nginx, puis l'élève constate que le pod recréé a une nouvelle IP.
- **Commande de l'init container** : reprise de l'énoncé, sans l'espace qui précédait `<h1>` (`echo ' <h1>…'`), pour une sortie plus propre. Sans effet sur les vérifications (elles cherchent `Hello from init`).
- **Étape 2, `$RANDOM`** : Kubernetes ne substitue que la syntaxe `$(VAR)` dans `command` ; `$RANDOM` est donc passé tel quel à `sh` (ash de busybox).
- **YAML donné à l'élève** : scénario pédagogique, pas de troubleshooting. Chaque étape montre le `spec` du template complet avec les blocs à ajouter marqués, comme `job-cronjob`. Pas de menus déroulants.
- **`k explain deploy.spec.template.spec.initContainers.restartPolicy`** à l'étape 2 : réflexe utile à l'examen pour retrouver ce champ.
- **Colonne `READY`** : `1/1` pour `dagobah` (l'init container terminé n'est pas compté), `2/2` pour `x-wing` (le sidecar natif est compté). Vérifié dans le code de l'impression des pods (`printPod`, `pkg/printers/internalversion/printers.go`, branche `master`).
- **Pas de `wait-for-prep.sh`** : préparation estimée sous 20 secondes (un seul téléchargement d'image, `nginx:alpine`). L'étape 1 commence par `k wait --for=condition=Available deploy --all`, avec la consigne de relancer si elle répond `no matching resources found`.
- **Vérifications (fond, pas seulement l'état)** :
  - le volume monté par nginx sous `/usr/share/nginx/html` (slash final toléré) est identifié par son nom, puis son type est contrôlé : `emptyDir` aux étapes 1 et 2, PVC `holocron` à l'étape 3 ;
  - étape 1 : un `initContainer` busybox **sans** `restartPolicy: Always` monte ce même volume au même endroit ;
  - étape 2 : un `initContainer` busybox **avec** `restartPolicy: Always` monte ce même volume ; un busybox dans `containers` (sidecar « classique ») est refusé ;
  - étape 3 : le PVC `holocron` est toujours `Bound` à `holocron-pv` ;
  - puis `kubectl rollout status --timeout=90s`, IP d'un pod `Ready` sans `deletionTimestamp`, et `curl` : `Hello from init` (étape 1), au moins 2 nombres différents sur 3 lectures espacées de 2 s (étape 2), `Archives Jedi` (étape 3).
  - images acceptées : `busybox`, `busybox:<tag>`, `busybox@<digest>` ; nginx reconnu par son image `nginx…`, pas par le nom du container.

## Sources officielles utilisées

- Sidecar containers : https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/ — stable depuis la v1.33 (disponible depuis la v1.28), déclaré dans `initContainers` avec `restartPolicy: Always`, exemple de partage d'un `emptyDir`.
- Blog Kubernetes 1.28 sur les sidecars natifs : https://kubernetes.io/blog/2023/08/25/native-sidecar-containers/ — `Always` est la seule valeur valide du champ.
- Volumes, `emptyDir` : https://kubernetes.io/docs/concepts/storage/volumes/#emptydir — partagé par tous les containers du pod, supprimé définitivement quand le pod quitte le nœud, conservé si un container plante.
- Code de `kube-apiserver` (impression des pods) : https://github.com/kubernetes/kubernetes/blob/master/pkg/printers/internalversion/printers.go — comptage des sidecars dans `READY`.
- Moteur jsonpath de kubectl : `staging/src/k8s.io/client-go/util/jsonpath` et `staging/src/k8s.io/cli-runtime/pkg/printers/jsonpath.go` (dépôt kubernetes/kubernetes, branche `master`).
- `$RANDOM` dans busybox : option `ASH_RANDOM_SUPPORT` (`default y`) dans `shell/ash.c` (lu sur un miroir des sources busybox 1.28.2, pas sur git.busybox.net) ; l'image officielle `busybox` (`latest` = variante glibc, 1.38.0 à la date de rédaction) est construite par `make defconfig` sans désactiver cette option (`docker-library/busybox`, `latest/glibc/Dockerfile.builder`).

## Limites connues

**Testé sur le papier uniquement** : ce scénario n'a pas été exécuté sur un cluster.

Ce qui a été fait :

- `bash -n` sur les 4 scripts, validité des JSON, présence des fichiers référencés dans `index.json` ;
- validation stricte contre le schéma Kubernetes 1.37 (paquet `kubernetes-validate` 1.37.0, non officiel) : les 3 manifests de départ, le PV et le PVC, et les 3 manifests obtenus en appliquant les blocs YAML des étapes aux fichiers générés par `intro-background.sh` (ce qui vérifie aussi que l'indentation des blocs correspond aux fichiers) ;
- logique des 3 scripts de vérification sur 30 cas (succès et échecs), avec un faux `kubectl` qui évalue les `jsonpath` avec le vrai moteur de client-go (compilé depuis les sources, `AllowMissingKeys(true)` comme kubectl) et un faux `curl`. Les objets JSON de test sont écrits à la main : ils ne reproduisent pas tous les champs ajoutés par l'API.

À vérifier au premier passage :

- **Version du backend** : l'énoncé annonce 1.37 ; le sidecar natif demande au moins 1.29 (1.33 pour la version stable). Le scénario ne dépend d'aucune version précise.
- **`$RANDOM` dans `busybox:latest`** : déduit de la configuration par défaut de busybox et du script de construction de l'image, pas exécuté. Si la page reste vide, c'est la première piste.
- **Joignabilité des IP de pods depuis `controlplane`** (Cilium) et présence de `curl` sur le nœud : supposées, comme dans les autres scénarios.
- **Durée de la préparation** : non mesurée. Si elle dépasse 20 secondes, ajouter `wait-for-prep.sh` comme dans `app-deploy/rolling-update`.
- **Variable `IP`** : suppose que chaque `{{exec}}` s'exécute dans le même shell du terminal, si bien que `IP=…` reste disponible pour le `curl` suivant.
- **`items[0]` juste après un rollout** : si l'ancien pod est encore `Terminating`, l'IP récupérée peut être la sienne. La consigne « attends qu'il disparaisse » le couvre ; les vérifications, elles, ignorent les pods en cours de suppression.
- **Lecture pendant l'écriture** : `echo … > index.html` vide puis réécrit le fichier ; un `curl` tombant entre les deux pourrait recevoir une page vide. Les vérifications tolèrent une lecture ratée sur trois.
- **Droits sur `/data/holocron`** : le worker nginx (utilisateur non root) doit lire `index.html` ; le script force `755` sur le répertoire et `644` sur le fichier.
- **`k explain deploy.spec.template.spec.initContainers.restartPolicy`** : chemin supposé valide, non exécuté.
- **Affichages cités** : `<h1>Welcome to nginx!</h1>` (page par défaut de `nginx:alpine`), `READY 1/1` et `2/2`, `no matching resources found`.
- **Environnement** : nœud unique planifiable, accès à Docker Hub pour `nginx:alpine` et `busybox`.
