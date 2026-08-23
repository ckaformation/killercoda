# Scénario Killercoda — RBAC : ServiceAccount d'un CronJob

## Contenu

```
rbac-cronjob-nettoyeur/
├── index.json
├── intro.md
├── intro-background.sh     # namespace, SA leon (sans RBAC), CronJob, 3 pods busybox
├── step1.md / step1-verify.sh   # diagnostic + Role/RoleBinding pour leon
├── step2.md / step2-verify.sh   # kubectl create job --from + vérification
├── step3.md / step3-verify.sh   # clonage de leon en leon-2 (export/vi/apply)
├── step4.md / step4-verify.sh   # kubectl edit rolebinding : ajout de leon-2
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

- **`schedule: "*/1 * * * *"` conservé à titre illustratif** dans le
  CronJob (pour que l'élève voie un planning réaliste dans
  `kubectl get cronjob`), mais sans effet réel puisque `suspend: true`
  empêche tout déclenchement automatique — voir plus bas.

- **CronJob créé suspendu (`spec.suspend: true`), demandé explicitement.**
  Sans ça, la planification (`*/1 * * * *`) continuerait à créer de
  nouveaux Jobs automatiquement en arrière-plan, y compris après la
  correction des droits RBAC — le nettoyage automatique pourrait alors
  survenir avant même que l'élève n'exécute `nettoyeur-manuel` à
  l'étape 2, rendant cette étape peu pertinente. Avec `suspend: true`,
  seul un déclenchement manuel (`kubectl create job --from=cronjob/...`)
  peut créer un Job à partir du modèle — ce mécanisme reste pleinement
  fonctionnel même CronJob suspendu, puisque `suspend` n'affecte que le
  déclenchement automatique par le contrôleur, pas la lecture du
  `jobTemplate`.

- **`backoffLimit: 0` + `restartPolicy: Never` sur le jobTemplate**,
  également pour garantir un échec "en un seul coup" : avec la
  configuration précédente (`restartPolicy: OnFailure`), le conteneur
  du pod aurait redémarré indéfiniment sur place (CrashLoopBackOff) à
  chaque échec, ce qui n'est ni un "essai unique" ni un signal propre à
  diagnostiquer. Avec `restartPolicy: Never`, le pod passe en `Failed`
  dès le premier échec du conteneur ; avec `backoffLimit: 0`, le Job ne
  recrée pas non plus de nouveau pod ensuite.

- **`nettoyeur-auto-1` : simulation déterministe de la "première
  tentative automatique".** Comme le CronJob est suspendu dès sa
  création, sa planification ne créera jamais de Job toute seule — donc
  pour donner à l'élève une preuve concrète à diagnostiquer en étape 1
  (logs d'un Job réellement en échec), le script de préparation crée
  lui-même, une seule fois et de façon fiable, un Job à partir du même
  `jobTemplate` (`kubectl create job nettoyeur-auto-1 --from=cronjob/nettoyeur`).
  Ça élimine aussi une source d'aléa que j'avais signalée dans une
  version précédente de ce README (dépendance au timing réel de la
  planification, potentiellement pas encore déclenchée selon la
  rapidité de l'élève).

- **`kubectl create job nettoyeur-manuel --from=cronjob/nettoyeur -n ops`**
  (étape 2, demandé explicitement) : copie le `jobTemplate` du CronJob
  (y compris `serviceAccountName: leon`) dans un Job immédiat, sans
  attendre la prochaine planification.

- **Étapes 3 et 4 : édition interactive (vi / `kubectl edit`), pas de
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
  sens pour un nouvel objet — les lister explicitement dans `step3.md`
  évite que l'élève tente un `kubectl apply` avec des valeurs
  obsolètes/non pertinentes. Je n'ai pas listé de champ `secrets:` à
  retirer : depuis Kubernetes 1.24, les ServiceAccounts ne génèrent
  plus automatiquement de Secret de token de longue durée, donc ce
  champ ne devrait pas apparaître dans l'export.

- **`automountServiceAccountToken` est un champ de premier niveau**
  (sibling de `metadata:`), pas imbriqué dans `metadata:` ni dans un
  `spec:` (l'objet `ServiceAccount` n'a pas de `spec`). Je l'ai
  explicitement signalé dans `step3.md` ("au même niveau que
  `metadata:`"), car c'est une erreur d'indentation facile à faire.

- **Étape 4 : ajout de `leon-2` au `RoleBinding` existant plutôt que
  création d'un nouveau `RoleBinding`** (demandé explicitement) — l'occasion
  de montrer qu'un `RoleBinding` peut lier plusieurs sujets à un même
  `Role`, sans duplication.

## Sources officielles utilisées

- https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- https://kubernetes.io/docs/concepts/security/service-accounts/
- https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/
- https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_job/
- https://kubernetes.io/docs/reference/kubectl/generated/kubectl_edit/

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le temps de pull de l'image `bitnami/kubectl:latest` n'a pas pu être
  vérifié en conditions réelles ; si le déclenchement (`nettoyeur-auto-1`
  en préparation, ou `nettoyeur-manuel` à l'étape 2) est lent à cause du
  pull d'image, le timeout de 90s dans `step2-verify.sh` pourrait
  s'avérer un peu juste — à ajuster après un premier test réel.
