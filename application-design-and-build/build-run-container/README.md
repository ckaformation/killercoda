# Scénario Killercoda — Build et run d'un container

## Contenu

```
build-run-container/
├── index.json                   # backend kubernetes-kubeadm-1node, 4 étapes
├── intro.md                     # podman, registry jedi-archives sur localhost:5000, ce que l'élève va faire
├── intro-background.sh          # wait-for-prep.sh, alias k, podman (apt), registries.conf.d, registry registry:2
├── step1.md / step1-verify.sh   # Dockerfile FROM bash + CMD ping, podman build / run --cap-add NET_RAW / logs
├── step2.md / step2-verify.sh   # podman save -o /root/r2d2.tar, rm + rmi, podman load -i
├── step3.md / step3-verify.sh   # podman tag localhost:5000/r2d2:v1, podman push, API /v2 de la registry
├── step4.md / step4-verify.sh   # k run r2d2 --image=localhost:5000/r2d2:v1, k get pods, k logs -f
└── finish.md
```

## Choix effectués et pourquoi

- **Emplacement** : le chemin demandé était `application-design-and-design`, qui n'existe pas. J'ai supposé une coquille pour le cours existant `application-design-and-build` (CKAD - Design & build). Pas de nouveau cours, donc pas de modification de `structure.json`.
- **Noms** : image, container podman et pod `r2d2` (R2-D2 émet des bips en boucle : le ping), registry `jedi-archives` (les archives où l'on range tout le savoir). Les vérifications imposent `/root/r2d2/Dockerfile`, `r2d2:v1`, le container `r2d2`, `/root/r2d2.tar`, `localhost:5000/r2d2:v1` et le pod `r2d2`.
- **Dockerfile** : `FROM bash` puis `CMD ["ping", "127.0.0.1"]`. L'entrypoint de l'image `bash` (`docker-entrypoint.sh`) exécute la commande reçue telle quelle.
- **`--cap-add NET_RAW` à l'étape 1** : trouvé au test. Podman 4.9.3 (Ubuntu 24.04) ne donne pas `NET_RAW` par défaut (`CapEff: 00000000800405fb`), et le `ping` de busybox n'a pas de repli sur les sockets ICMP non privilégiées : sans la capability, le container s'arrête avec `ping: permission denied (are you root?)`, malgré `net.ipv4.ping_group_range=0 0` posé par podman. J'ai préféré l'option explicite, avec une phrase d'explication, à une modification invisible de `containers.conf` : c'est aussi l'occasion de montrer à l'étape 4 que containerd, lui, accorde `NET_RAW` par défaut (lien avec `securityContext.capabilities` dans `finish.md`). Alternative possible si tu préfères une commande plus courte : ajouter `NET_RAW` à `default_capabilities` dans `/etc/containers/containers.conf.d/` depuis `intro-background.sh`.
- **`podman rm -f r2d2` prend 10 s** : `ping`, PID 1 du container, ignore SIGTERM ; podman attend 10 s puis envoie SIGKILL (avertissement `StopSignal SIGTERM failed to stop container r2d2 in 10 seconds`). Expliqué en une ligne plutôt qu'avec `-t 0`, dont je n'ai pas vérifié la disponibilité sur les anciennes versions de podman.
- **Nom court `bash`** : sur Ubuntu, `/etc/containers/registries.conf` ne définit aucun `unqualified-search-registries` et `shortnames.conf` ne contient pas d'alias pour `bash` : `FROM bash` échouerait. `intro-background.sh` ajoute `unqualified-search-registries = ["docker.io"]` dans `/etc/containers/registries.conf.d/99-scenario.conf`. Avec un seul registre de recherche, podman ne pose pas de question.
- **Registry `insecure`** : le même fichier déclare `localhost:5000` en `insecure = true`. Sans cela, le push échoue avec `http: server gave HTTP response to HTTPS client` (constaté). L'énoncé le signale et cite l'alternative `--tls-verify=false`.
- **Registry sur le réseau de l'hôte** (`--network host`) : pas de NAT ni de règle de pare-feu podman entre containerd et la registry ; `localhost:5000` est le même pour podman et pour containerd. Le stockage de la registry est dans le container (pas de volume) : il est perdu si le container est supprimé, ce qui ne se produit pas dans le scénario.
- **Rien côté containerd** : containerd contacte `localhost` en HTTP par défaut. Testé avec containerd 2.4.2, avec `config_path` vide comme avec `config_path` vers un dossier `certs.d` sans entrée pour `localhost:5000`.
- **`wait-for-prep.sh`** : installation de podman par `apt` et téléchargement de `registry:2` : bien plus de 20 secondes. Modèle `app-deploy/rolling-update`, avec en plus un état final (version de podman, réponse de la registry). La sentinelle est créée à la fin même si une étape a échoué, pour que l'élève voie le message d'erreur plutôt qu'une attente de 7 minutes.
- **Chemins absolus** pour l'archive (`/root/r2d2.tar`) : les commandes restent valables si l'élève change de dossier ou ouvre un autre onglet de terminal.
- **Étape 4 sans `--cap-add`** et sans `imagePullPolicy` : avec le tag `v1` (pas `latest`), la valeur par défaut est `IfNotPresent` ; l'image n'existe pas dans le stockage de containerd, elle est donc téléchargée depuis la registry.
- **Vérifications (fond, pas seulement l'état)** :
  - étape 1 : `FROM` sur l'image `bash` (`bash`, `bash:<tag>`, `docker.io/library/bash…`), image `localhost/r2d2:v1` dont l'`Entrypoint`/`Cmd` contient `ping` et `127.0.0.1`, container `r2d2` créé sur **cette** image (comparaison des ID), `running`, et réponses `bytes from 127.0.0.1` dans ses logs. Si le container est arrêté sur `permission denied`, le message parle de `NET_RAW` ;
  - étape 2 : archive valide (`manifest.json` avec le tag `localhost/r2d2:v1`), image locale identique à celle de l'archive (ID présent dans `manifest.json`), et, si `podman events` répond, la séquence `save` → `remove` de `r2d2:v1` → `loadfromarchive` dans les 3 dernières heures ;
  - étape 3 : registry joignable, nom local `localhost:5000/r2d2:v1`, tag `v1` dans la registry, et manifeste de la registry qui référence le digest de configuration de l'image locale (l'ID d'une image podman est ce digest) : une autre image poussée sous ce nom est refusée ;
  - étape 4 : pod `r2d2` avec l'image exacte `localhost:5000/r2d2:v1`, `Ready` (attente 60 s, raison affichée sinon, par ex. `ImagePullBackOff`), et réponses du ping dans `k logs`.

## Sources officielles utilisées

- Création de scénarios Killercoda : https://killercoda.com/creators
- Images dans Kubernetes (`imagePullPolicy` par défaut) : https://kubernetes.io/docs/concepts/containers/images/
- `kubectl run` : https://kubernetes.io/docs/reference/kubectl/generated/kubectl_run/
- Security context et capabilities : https://kubernetes.io/docs/tasks/configure-pod-container/security-context/
- Configuration de podman : fichiers livrés par le paquet Ubuntu 24.04 (`/usr/share/containers/containers.conf`, `/etc/containers/registries.conf`, `/etc/containers/registries.conf.d/shortnames.conf`), lus dans mon environnement de test.

## Limites connues

**Testé sur le papier uniquement** pour la partie Killercoda et Kubernetes : le scénario n'a pas été exécuté sur un cluster.

Ce qui a été testé, dans mon environnement (Ubuntu 24.04, podman 4.9.3 du paquet Ubuntu, netavark, runc de containerd.io) :

- `intro-background.sh` (avec un faux `kubectl`), deux fois de suite (idempotence), puis `wait-for-prep.sh` ;
- les étapes 1 à 3 telles qu'écrites, commande par commande, et les scripts de vérification 1 à 3 en échec puis en succès (Dockerfile absent ou mauvais `FROM`, image absente, container absent, container arrêté faute de `NET_RAW`, archive absente, `load` sans suppression préalable, nom non taggé, registry contenant une autre image) ;
- le téléchargement par containerd 2.4.2 (`crictl` v1.36.0) de `localhost:5000/r2d2:v1` en HTTP, et le ping dans un container lancé avec les capabilities par défaut de containerd (`ctr run`) ;
- `step4-verify.sh` avec un faux `kubectl` (pod absent, mauvaise image, `ImagePullBackOff`, logs sans réponse, succès).

Docker Hub n'est pas joignable depuis mon environnement : l'image `bash` a été remplacée par une image locale contenant busybox 1.36.1 (Ubuntu), et `registry:2` par une image locale contenant le binaire officiel `distribution` v2.8.3 avec la configuration de l'image officielle.

À vérifier au premier passage :

- **OS du backend** : supposé Ubuntu avec `apt`. Si ce n'est pas Ubuntu 24.04, la version de podman diffère (3.4.4 sur 22.04, avec CNI au lieu de netavark) : messages et format de `podman images` possiblement différents.
- **Installation de podman sur le nœud Kubernetes** : durée non mesurée ; `apt-get update` peut signaler des erreurs de dépôt (ignorées). Dépendance `crun | runc` : supposée satisfaite sans conflit avec le paquet containerd du backend. Avec podman 3.x (CNI), le fichier `87-podman-bridge.conflist` irait dans `/etc/cni/net.d` ; Cilium (`05-cilium…`) resterait premier dans l'ordre alphabétique, donc toujours utilisé par containerd. Non vérifié.
- **Réseau par défaut de podman** (`10.88.0.0/16`) pour le container `r2d2` de l'étape 1 : supposé sans conflit avec les plages de Cilium sur le backend.
- **Ping de l'image `bash` réelle** : c'est le busybox d'Alpine ; même code que le busybox testé, mais pas exécuté. Même chose pour l'affichage `64 bytes from 127.0.0.1: seq=0 ttl=64 ...`.
- **Version de containerd du backend** : seul containerd 2.4.2 a été testé pour le HTTP par défaut vers `localhost`.
- **Capabilities dans le pod** : `NET_RAW` par défaut vérifié avec `ctr run`, pas avec un vrai pod (CRI et Cilium).
- **Port 5000 libre** sur le nœud : supposé.
- **Limites de téléchargement anonymes de Docker Hub** (`bash`, `registry:2`) : non vérifiées sur Killercoda.
- **`podman events`** : testé avec le journal `file`. Sur le backend, ce sera probablement `journald` ; si la commande ne renvoie rien, la vérification 2 saute ce contrôle au lieu d'échouer.
- **Version de Kubernetes** : l'énoncé annonce 1.37 ; le scénario ne dépend d'aucune version précise.
