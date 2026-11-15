# Scénario Killercoda — Job et CronJob : exécuter et planifier une tâche

## Contenu

```
job-cronjob/
├── index.json                   # backend kubernetes-kubeadm-1node, 2 étapes
├── intro.md                     # Job vs Deployment, CronJob, ce qui est déjà en place
├── intro-background.sh          # alias k, ns tatooine, ConfigMap + Deployment + Service holonet
├── step1.md / step1-verify.sh   # k create job --dry-run, completions: 3 ajouté à la main, apply, wait, logs
├── step2.md / step2-verify.sh   # k create cronjob --dry-run, successfulJobsHistoryLimit + activeDeadlineSeconds, déclenchement manuel
└── finish.md
```

## Choix effectués et pourquoi

- **Préparation** (namespace `tatooine`) : ConfigMap `holonet-index` (clé `index.html`, avec la phrase « Que la Force soit avec ce cluster, padawan ! »), Deployment `holonet` (1 réplica, `nginx:alpine`, ConfigMap monté sous `/usr/share/nginx/html`) et Service `holonet` (port 80).
- **Noms** : Job `holonet-ping`, CronJob `holonet-cron`, Job manuel `holonet-cron-manual`. Ils sont imposés car les scripts de vérification les utilisent.
- **`-n tatooine` explicite** à chaque commande, plutôt qu'un changement du namespace du context.
- **« Se terminer après 30 secondes maximum » = `activeDeadlineSeconds: 30` dans `jobTemplate.spec`** (durée d'exécution d'un Job). Ce n'est pas `startingDeadlineSeconds` (délai de démarrage d'un Job dont l'échéance a été manquée) : l'étape 2 explique la différence. C'est une interprétation de la consigne.
- **Édition du YAML à la main** : `k create job` n'a pas d'option pour `completions`, et `k create cronjob` n'en a ni pour l'historique ni pour la durée maximale. L'élève génère le manifeste (commande exécutable, sans champ à compléter), puis ajoute les champs avec `vi`.
- **Pas de `wait-for-prep.sh`** : la préparation est estimée à moins de 20 secondes (le téléchargement de `nginx:alpine` en est la part principale). L'étape 1 commence par `k rollout status`, avec une consigne d'attente, comme dans `fundamentals/services`.
- **Vérification du déclenchement manuel** : `step2-verify.sh` cherche un Job autre que `holonet-ping`, terminé avec succès, qui porte `activeDeadlineSeconds: 30` (hérité du `jobTemplate`) et dont les logs contiennent la page. Cela accepte le Job manuel quel que soit son nom, ainsi qu'un Job planifié, et ne dépend pas des `ownerReferences`.
- **Planning accepté** : `*/15 * * * *` ou `0,15,30,45 * * * *`.
- **Vérification de l'étape 1** : image `curlimages/curl` (avec ou sans tag), `completions: 3`, `status.succeeded: 3`, et au moins 3 occurrences de la phrase dans les logs des pods du Job (donc le `curl` a bien joint le Service). La forme du nom DNS n'est pas figée.
- **Pas de menus déroulants** : ce n'est pas un scénario de troubleshooting.

## Sources officielles utilisées

- Documentation des CronJobs (version 1.32) : https://v1-32.docs.kubernetes.io/docs/concepts/workloads/controllers/cron-jobs — valeurs par défaut de `successfulJobsHistoryLimit` (3) et `failedJobsHistoryLimit` (1), sens de `startingDeadlineSeconds`, syntaxe cron à 5 champs avec pas `*/N`.
- Documentation des Jobs, traduction indonésienne : https://kubernetes.io/id/docs/concepts/workloads/controllers/job/ — la page anglaise n'était pas accessible, et cette version peut être en retard sur l'originale. Elle donne : `completions` et `parallelism` valent 1 par défaut, `restartPolicy` `Never` ou `OnFailure` seulement, `activeDeadlineSeconds` (pods arrêtés, Job `Failed` avec la raison `DeadlineExceeded`), pods terminés non supprimés.
- Code source de `kubectl` (branche `master`) : `pkg/cmd/create/create_job.go` et `create_cronjob.go` — `k create job` génère `restartPolicy: Never`, `k create cronjob` utilise `OnFailure` par défaut, `k create job --from=cronjob/…` reprend `jobTemplate.spec` du CronJob, et le namespace n'est écrit dans le manifeste que si `-n` est passé.
- Référence de l'API Job : reproduite par la documentation OpenShift 4.16 de Red Hat (pas une page kubernetes.io) — descriptions de `activeDeadlineSeconds`, `completions`, `parallelism`.
- Les liens du `finish.md` pointent vers les pages anglaises canoniques de kubernetes.io (Jobs, CronJobs), que je n'ai pas pu ouvrir : j'ai lu les deux pages ci-dessus à leur place.

## Limites connues

**Testé sur le papier uniquement** : ce scénario n'a pas été exécuté sur un cluster.

Ce qui a été fait :

- `bash -n` sur les trois scripts, validité des JSON ;
- validation des manifestes contre le schéma Kubernetes 1.35.0 (outil `kubeconform`, mode strict, schémas du projet `yannh/kubernetes-json-schema`, qui n'est pas une source officielle) : ConfigMap, Deployment et Service de la préparation ; Job avec `completions: 3` ; CronJob avec ses deux champs ajoutés. Cela prouve les **emplacements des champs**, pas ce que `kubectl` génère ;
- logique de `step1-verify.sh` (11 cas) et `step2-verify.sh` (14 cas), succès et échecs, avec un faux `kubectl` écrit pour l'occasion : ces tests ne disent rien du comportement réel de `kubectl`.

À vérifier au premier passage :

- **Sortie réelle de `k create job … -o yaml` et `k create cronjob … -o yaml`** : j'ai lu le code (valeurs de `restartPolicy`), mais je n'ai pas exécuté les commandes. Les indications d'insertion des étapes supposent un `spec:` en colonne 0 et, pour le CronJob, `jobTemplate.spec` puis `template`.
- **Image `curlimages/curl`** : `command: [curl, holonet.tatooine]` (ce que produit `--`) remplace l'entrypoint de l'image ; je suppose que `curl` est dans le `PATH` de l'image.
- **Label des pods d'un Job** : `step1-verify.sh` lit les logs avec `batch.kubernetes.io/job-name`, puis se replie sur `job-name` (le seul que j'ai vu dans la documentation lue, dans un exemple ancien). Même remarque pour `k logs -l … --tail=-1`.
- **`k logs job/<nom>`** : suppose que `kubectl` choisit un des pods du Job.
- **`k explain cronjob.spec.jobTemplate.spec.activeDeadlineSeconds`** : chemin supposé valide.
- **Affichages cités** : `COMPLETIONS 3/3`, pods `Completed`, valeur `30` du `jsonpath`.
- **Durées** : trois pods s'enchaînent (`parallelism` à 1) et le premier télécharge l'image. `step1-verify.sh` attend jusqu'à 180 s, `step2-verify.sh` jusqu'à 120 s pour le Job manuel.
- **Préparation sans `wait-for-prep.sh`** : durée non mesurée. Si elle dépasse 20 secondes, ajouter le script d'attente comme dans `app-deploy/rolling-update`.
- **Page servie** : suppose que nginx sert le fichier du ConfigMap monté sur tout `/usr/share/nginx/html` (le montage masque le contenu par défaut du répertoire, ce qui est voulu).
- **Environnement** : nœud unique planifiable, accès à Docker Hub pour `nginx:alpine` et `curlimages/curl`.
- **Non affirmé dans le scénario** : l'immutabilité de `completions` (je n'ai trouvé aucune source qui la confirme ou l'infirme). Le message de vérification conseille simplement de supprimer le Job et de le recréer.
