# Scénario Killercoda — Probes : readiness et liveness

## Contenu

```
observability-and-maintenance/pod-health-probes/
├── index.json                   # backend kubernetes-kubeadm-1node, 3 étapes
├── intro.md
├── intro-background.sh          # alias k, /root/echo-base.yaml, namespace hoth, Deployment echo-base sans probe
├── step1.md / step1-verify.sh   # readinessProbe httpGet /healthz:80, initialDelaySeconds 5, periodSeconds 10
├── step2.md / step2-verify.sh   # livenessProbe exec "stat /tmp/life-signs", initialDelaySeconds 10, periodSeconds 7, failureThreshold 1
├── step3.md / step3-verify.sh   # rm /tmp/life-signs -> le kubelet redémarre le conteneur (même pod)
├── finish.md
└── README.md
```

Nouveau cours : `observability-and-maintenance`, ajouté à la fin de `structure.json`.

## Choix effectués et pourquoi

- **Noms Star Wars** : namespace `hoth`, Deployment `echo-base` (la base rebelle de *L'Empire contre-attaque*), fichier `/tmp/life-signs` (« signes de vie », pour la liveness).
- **Image `nginx:alpine` avec une commande de démarrage** :
  ```
  touch /tmp/life-signs
  echo ok > /usr/share/nginx/html/healthz
  exec nginx -g 'daemon off;'
  ```
  - nginx ne sert pas `/healthz` par défaut (404) : un fichier statique suffit pour que la readinessProbe reçoive un 200, sans ConfigMap.
  - `/tmp/life-signs` est créé au démarrage, comme demandé. Après un redémarrage, le nouveau conteneur repart de l'image et le recrée : c'est ce qui permet au pod de revenir à la normale à l'étape 3.
  - `exec` fait de nginx le PID 1. Il reçoit donc directement le SIGTERM envoyé par le kubelet quand la liveness échoue et s'arrête tout de suite. Avec `sh` en PID 1, le signal ne serait pas transmis et l'arrêt attendrait `terminationGracePeriodSeconds` (30 s).
  - `command` remplace l'entrypoint de l'image (`/docker-entrypoint.sh`) : ses scripts d'initialisation (écoute IPv6, templates…) ne sont pas lancés. Ils ne servent pas ici ; c'est pour cela que le test `wget` de l'étape 1 vise `127.0.0.1` et pas `localhost` (qui pourrait se résoudre en `::1`).
- **Port 80 dans la readinessProbe** : la demande donnait seulement le path ; une probe `httpGet` exige un port, et le conteneur écoute sur 80.
- **Modification par fichier** (`vi /root/echo-base.yaml` puis `kubectl apply -f`), le même fichier pour les étapes 1 et 2 : approche déclarative, et l'élève voit le manifeste complet. Les blocs YAML sont donnés tels quels (scénario pédagogique : ni indice ni solution en menu déroulant). Procédure vi donnée pas à pas, avec `:set paste` pour éviter le décalage d'indentation au collage.
- **Étape 1** : `kubectl get pods -w` montre que le nouveau pod reste `0/1` jusqu'au succès de la readinessProbe, et que l'ancien n'est arrêté qu'ensuite (stratégie par défaut : avec 1 réplica, `maxSurge` 25 % donne 1 et `maxUnavailable` 25 % donne 0). `describe | grep Readiness` fait apparaître les valeurs par défaut (`timeout`, `#success`, `#failure`).
- **Étape 2** : test manuel de `stat` avec `kubectl exec`, puis `echo $?`, pour montrer le critère de succès d'une probe `exec` (code de sortie 0).
- **Étape 3** : `rm` par `kubectl exec`, puis `get pods -w` (même nom de pod, `RESTARTS` à 1), événements `Unhealthy` / `Killing`, et retour du fichier.
- **Vérifications orientées fond** :
  - étapes 1 et 2 : chaque champ demandé (path, port, délais, période, seuil, commande), rollout terminé, pod prêt ; l'étape 2 contrôle aussi que la readinessProbe est toujours là ;
  - étape 3 : liveness inchangée, `restartCount` ≥ 1 sur le pod en cours (un pod supprimé puis recréé repart à 0, donc refusé), événement contenant « liveness probe » pour ce pod, pod de nouveau prêt, fichier recréé. Si le pod n'est pas encore prêt, le message invite à relancer la vérification.
- **Pas de `wait-for-prep.sh`** : la préparation (un namespace et un Deployment `nginx:alpine`) devrait rester sous 20 s. Le manifeste est écrit avant l'attente de l'API pour être disponible immédiatement ; la première commande de l'étape 1 invite à attendre que le pod soit `1/1`.
- **Pas de Service** : non demandé. L'effet de la readiness sur le trafic est seulement expliqué dans le texte.
- **Titre du cours** : « CKAD - Observabilité et maintenance des applications », d'après le domaine CKAD *Application Observability and Maintenance* repris dans le nom du dossier.

## Sources officielles utilisées

- Configurer les probes (exemple `exec` avec `/tmp/healthy`, événements `Liveness probe failed` / `failed liveness probe, will be restarted`, compteur `RESTARTS`) : https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- Concepts (la readiness s'exécute pendant toute la vie du conteneur ; la liveness n'attend pas la readiness) : https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- Configuration busybox d'Alpine (`CONFIG_STAT=y`, `CONFIG_WGET=y`, `CONFIG_TOUCH=y`, vérifiée sur la branche `master` d'aports) : https://github.com/alpinelinux/aports/blob/master/main/busybox/busyboxconfig
- Doc Killercoda : https://killercoda.com/creators

## Limites connues

**Testé sur le papier uniquement.** Ce qui a été contrôlé : JSON (`structure.json`, `index.json`), syntaxe bash de tous les scripts, YAML du manifeste généré puis du manifeste obtenu après collage des blocs des étapes 1 et 2 en fin de fichier, et les trois vérifications jouées en échec puis en succès (28 cas) avec un faux `kubectl` dont l'évaluation jsonpath est simplifiée : les expressions jsonpath elles-mêmes n'ont pas été exécutées par un vrai `kubectl`. Hypothèses à vérifier au premier passage :

- **Version** : la demande mentionne un environnement v1.37. Le scénario n'utilise rien de propre à une version et ne la vérifie pas.
- **`/healthz` en 200** : nginx doit servir le fichier statique `/usr/share/nginx/html/healthz` (sans extension) avec un code 200. Attendu avec la configuration par défaut de l'image, non observé.
- **`stat`, `wget` et `touch` dans `nginx:alpine`** : fournis par busybox d'après la configuration d'Alpine sur `master` ; non vérifié sur l'image réellement tirée.
- **Arrêt rapide du conteneur** : avec `exec nginx`, le SIGTERM du kubelet doit arrêter nginx en une ou deux secondes. Non observé.
- **Chronologie de l'étape 3** : échec de la liveness au plus 7 s après le `rm`, redémarrage, puis pod de nouveau `1/1` 5 à 15 s plus tard (readinessProbe). Non observé ; l'affichage exact de `get pods -w` pendant le redémarrage (`0/1`, éventuel statut intermédiaire) n'est pas garanti.
- **Texte des événements** : `step3-verify.sh` cherche « liveness probe » (sans tenir compte de la casse) dans les messages d'événements du pod. Je m'appuie sur les messages de la documentation officielle (`Liveness probe failed: …`, `Container … failed liveness probe, will be restarted`). Si le texte diffère en 1.37, la vérification échouera à tort.
- **Format de `kubectl describe`** : les lignes `Readiness:` / `Liveness:` (`delay=…s timeout=…s period=…s #success=… #failure=…`) citées dans les étapes 1 et 2 sont écrites de mémoire.
- **Durée de la préparation** : estimée sous 20 s (pull de `nginx:alpine` compris). Si elle dépasse nettement, ajouter `wait-for-prep.sh`.
- **`:set paste`** : supposé disponible dans le `vi` du backend (vim). Sinon, coller sans cette option et contrôler l'indentation.
- **Lien « Les trois types de probes »** du `finish.md` : URL non vérifiée par un fetch (la page pourrait avoir été déplacée vers `/docs/concepts/workloads/pods/probes/`).
