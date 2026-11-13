# Scénario Killercoda — RBAC : ServiceAccount d'un CronJob

## Contenu

```
rbac-cronjob-nettoyeur/
├── index.json
├── intro.md
├── intro-background.sh     # namespace, SA leon (sans RBAC), CronJob, 3 pods busybox
├── step1.md / step1-verify.sh   # diagnostic + Role/RoleBinding pour leon + vérif nettoyage auto
├── step2.md / step2-verify.sh   # clonage de leon en leon-2 (export/vi/apply)
├── step3.md / step3-verify.sh   # kubectl edit rolebinding : ajout de leon-2
└── finish.md
```

## Choix effectués et pourquoi

- **Backend : `kubernetes-kubeadm-1node`**, identique à `rbac-luke-jedi`,
  pour les mêmes raisons (cluster déjà installé, pas de reset nécessaire
  pour un exercice RBAC). Alias `k` mis en place de la même façon (lien
  symbolique, pas d'alias bash — cf. le README de `rbac-luke-jedi`).

- **ServiceAccount `leon` pré-créé, sans aucun RBAC.** Un `Pod` dont le
  `serviceAccountName` référence un ServiceAccount inexistant échoue à
  l'admission (le pod ne démarre même pas) — j'ai donc dû créer le
  ServiceAccount pour que le CronJob puisse au moins démarrer, et
  échouer ensuite pour la vraie raison pédagogique : l'absence de droits
  RBAC, qui se manifeste par une erreur `Forbidden` au moment de l'appel
  à l'API depuis l'intérieur du conteneur.

- **Image `bitnami/kubectl:latest`** pour le conteneur du CronJob : choix
  courant et largement utilisé en pratique pour ce genre de job
  utilitaire "kubectl dans un pod". Alternative possible :
  `rancher/kubectl` ou l'image officielle `registry.k8s.io/kubectl` si
  celle-ci existe et convient mieux à ton contexte — à ajuster si le
  temps de pull s'avère problématique sur Killercoda.

- **Droits accordés à `leon` : `get`, `list`, `delete` sur `pods`,**
  limités au namespace `ops` (`Role` + `RoleBinding`, pas de
  `ClusterRole`). `list` est nécessaire pour que
  `--field-selector=status.phase=Succeeded` puisse filtrer les pods
  côté serveur ; `get` est inclus par prudence/complétude ; `delete`
  pour la suppression elle-même. Aucun droit sur d'autres ressources
  n'est accordé : le ServiceAccount reste avec le minimum nécessaire.

- **Usurpation d'un ServiceAccount** : `--as=system:serviceaccount:ops:leon`
  (syntaxe différente de l'usurpation d'un utilisateur externe, comme
  `luke` dans `rbac-luke-jedi`, qui s'usurpe simplement avec
  `--as=luke`).

- **3 pods busybox (`echo done`, `restartPolicy: Never`)** : demandé
  explicitement, pour donner au CronJob un état réel à nettoyer.
  Utilisent `kubectl run ... --command -- echo done` (le flag
  `--command` force "echo done" à devenir la commande du conteneur,
  plutôt que des arguments ajoutés à l'entrypoint par défaut de l'image
  — évite toute ambiguïté sur le comportement exact de busybox).

- **CronJob planifié normalement (`*/1 * * * *`), pas de `suspend`, pas
  de job manuel.** Versions précédentes de ce scénario ont exploré deux
  approches différentes pour éviter qu'un CronJob en échec ne
  s'acharne à se relancer : d'abord `spec.suspend: true` + un Job
  simulé par le script de préparation, puis un déclenchement manuel
  (`kubectl create job --from=cronjob/...`) en étape dédiée. Les deux
  ont été abandonnées sur demande : `restartPolicy: Never` +
  `backoffLimit: 0` (voir ci-dessous) suffisent à éviter qu'un Job
  donné ne s'acharne à se relancer tout seul en cas d'échec, et c'est
  le déclenchement automatique du CronJob lui-même (une fois les
  droits corrigés) qui effectue le nettoyage — vérifié à la fin de
  l'étape 1, plutôt que via un Job manuel dédié.

- **`backoffLimit: 0` + `restartPolicy: Never` sur le jobTemplate**,
  pour qu'un Job donné échoue "en un seul coup" plutôt que de
  redémarrer indéfiniment sur place (`CrashLoopBackOff`), comme
  c'était le cas avec la configuration initiale
  (`restartPolicy: OnFailure`). Avec `restartPolicy: Never`, le pod
  passe en `Failed` dès le premier échec du conteneur ; avec
  `backoffLimit: 0`, le Job ne recrée pas non plus de nouveau pod
  ensuite. Ça ne concerne qu'un Job pris isolément : le CronJob, lui,
  continue de créer un nouveau Job à chaque tick de sa planification.

- **`terminationGracePeriodSeconds: 1`**, demandé explicitement, sur le
  jobTemplate : réduit la période de grâce à la terminaison d'un pod
  (1 seconde au lieu des 30 secondes par défaut), pour que les pods du
  CronJob (notamment ceux en échec) se terminent rapidement plutôt que
  d'attendre inutilement.

- **Étape 1, section 5 : vérification du nettoyage automatique**
  (demandé explicitement, remplace l'ancienne étape de job manuel).
  Une fois les droits corrigés, l'élève observe (`watch kubectl get
  pods -n ops`) la disparition des 3 pods cibles au prochain
  déclenchement planifié du CronJob — jusqu'à 60 secondes d'attente,
  selon le moment où les droits sont corrigés par rapport au prochain
  tick. `step1-verify.sh` reflète ça avec une boucle d'attente de 90s
  au total sur la disparition effective des 3 pods, après avoir
  confirmé les droits RBAC.

- **Étapes 2 et 3 : édition interactive (vi / `kubectl edit`), pas de
  commandes 100% automatisables.** Contrairement au reste du projet
  (tout en `{{exec}}` cliquables), ces deux étapes demandent
  explicitement d'éditer un fichier (`vi sa.yaml`) puis un objet
  Kubernetes en place (`kubectl edit rolebinding`). C'est un choix
  assumé, cohérent avec la demande initiale, et réaliste par rapport à
  la pratique réelle (et aux exercices type CKA). Les `verify.sh`
  correspondants ne vérifient donc que l'**état final** (le
  ServiceAccount `leon-2` existe avec le bon champ, `leon-2` a bien le
  droit `delete` sur les pods), pas la méthode utilisée pour y arriver.

- **Champs à retirer lors du clonage de `leon` en `leon-2`**
  (`resourceVersion`, `uid`, `creationTimestamp`) : ce sont des champs
  gérés par le serveur, présents dans l'export mais qui n'ont pas de
  sens pour un nouvel objet — les lister explicitement dans `step2.md`
  évite que l'élève tente un `kubectl apply` avec des valeurs
  obsolètes/non pertinentes. Je n'ai pas listé de champ `secrets:` à
  retirer : depuis Kubernetes 1.24, les ServiceAccounts ne génèrent
  plus automatiquement de Secret de token de longue durée, donc ce
  champ ne devrait pas apparaître dans l'export.

- **`automountServiceAccountToken` est un champ de premier niveau**
  (sibling de `metadata:`), pas imbriqué dans `metadata:` ni dans un
  `spec:` (l'objet `ServiceAccount` n'a pas de `spec`). Je l'ai
  explicitement signalé dans `step2.md` ("au même niveau que
  `metadata:`"), car c'est une erreur d'indentation facile à faire.

- **Étape 3 : ajout de `leon-2` au `RoleBinding` existant plutôt que
  création d'un nouveau `RoleBinding`** (demandé explicitement) — l'occasion
  de montrer qu'un `RoleBinding` peut lier plusieurs sujets à un même
  `Role`, sans duplication.

## Sources officielles utilisées

- https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- https://kubernetes.io/docs/concepts/security/service-accounts/
- https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
- https://kubernetes.io/docs/reference/kubectl/generated/kubectl_edit/

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le temps de pull de l'image `bitnami/kubectl:latest` n'a pas pu être
  vérifié en conditions réelles ; si un déclenchement planifié est lent
  à cause du pull d'image, le timeout de 90s dans `step1-verify.sh`
  pourrait s'avérer un peu juste — à ajuster après un premier test
  réel.
- Comme le CronJob se déclenche automatiquement toutes les minutes dès
  le début du scénario, un ou plusieurs Jobs en échec (et leurs pods)
  peuvent s'accumuler dans `ops` avant que l'élève ne corrige les
  droits ; ça n'empêche pas le scénario de fonctionner, mais ça peut
  rendre `kubectl get pods -n ops` un peu bruyant à l'étape 1.
- La vérification finale de l'étape 1 peut prendre jusqu'à une minute
  (le temps que le CronJob se déclenche à nouveau) après la correction
  des droits : c'est normal et attendu, pas une erreur.
