# Scénario Killercoda — Rollouts : stratégie, pause/reprise et rollback

## Contenu

```
rollout-deployments/
├── index.json                   # backend kubernetes-kubeadm-1node, 3 étapes
├── intro.md
├── intro-background.sh          # alias k + wait-for-prep.sh + 3 Deployments (namespace default)
├── step1.md / step1-verify.sh   # wait-for-prep.sh ; millennium-falcon : un seul kubectl edit (Recreate -> RollingUpdate 1 / 0 + APP_RELEASE) + rollout status
├── step2.md / step2-verify.sh   # death-star : rollout en pause -> rollout resume
├── step3.md / step3-verify.sh   # tie-fighter (1 réplica, Recreate) : 4 révisions, la 4e défectueuse -> rollout undo --to-revision=2
└── finish.md
```

## Préparation (intro-background.sh)

| Deployment | Réplicas | État initial |
|---|---|---|
| `millennium-falcon` | 2 | `nginx:alpine`, `APP_RELEASE="v2"`, stratégie `Recreate` |
| `death-star` | 1 | déployé en `APP_RELEASE="v1"`, rollout terminé, puis **mis en pause**, puis modifié en `APP_RELEASE="v2"` |
| `tie-fighter` | 1 | stratégie `Recreate` ; révisions 1 (initial, v1), 2 (v2 config changes), 3 (v3 rollout), 4 (v3 hotfix : `command: ["nginx","-c","/etc/nginx/hotfix.conf"]`, fichier inexistant) |

Les libellés des révisions de `tie-fighter` sont posés avec l'annotation `kubernetes.io/change-cause` dans chaque manifeste appliqué.

`intro-background.sh` dépose `/root/wait-for-prep.sh` dès le début. Ce script attend le fichier `/tmp/.scenario-prep-done`, créé tout à la fin de la préparation, **uniquement une fois que le pod de `tie-fighter` est observé en `CrashLoopBackOff`** (attente maximale de 180 s dans la préparation, 420 s côté `wait-for-prep.sh`). L'étape 1 commence par le lancer.

## Écart avec la demande initiale

La demande disait que `death-star` « a subi une modif qui a généré une 2ème révision mais que le rollout ne se fait pas ». Telle quelle, cette phrase ne correspond pas au comportement attendu d'un Deployment en pause : tant qu'il est en pause, une modification du pod template est enregistrée dans le spec, mais aucun nouveau ReplicaSet (donc aucune nouvelle révision) n'est créé. La révision 2 apparaît au `rollout resume`. Le scénario est écrit dans ce sens : l'étape 2 fait constater une seule révision avant la reprise, et deux après.

## Choix effectués

- **Noms Star Wars** pour les Deployments, tous dans `default` comme demandé.
- **Étape 1 : un seul `kubectl edit`** pour la stratégie et la variable, avec les bonnes valeurs données telles quelles dans les blocs (avant/après pour la stratégie, la ligne `value: "v3"` pour la variable). L'élève fait les modifications à la main dans vi ; l'énoncé rappelle les touches vi utiles et la recherche `/strategy` et `/APP_RELEASE`. Une seule révision est créée (celle de la variable), ce que l'étape fait constater à la fin. La démonstration « changer la stratégie seule ne crée pas de révision » n'est donc plus faite en pratique ; elle reste citée dans `finish.md`, qui est inchangé.
- **1 réplica pour `death-star` et `tie-fighter`** (2 pour `millennium-falcon`, dont la mise à jour progressive doit rester visible).
- **`tie-fighter` en `Recreate`** : avec un seul réplica, l'ancien pod (révision 3) est arrêté avant le démarrage du nouveau. À la révision 4, il ne reste donc qu'un pod, en `CrashLoopBackOff`, et le Deployment est indisponible (`READY 0/1`, `AVAILABLE 0`), ce que l'élève doit voir. La stratégie ne fait pas partie du pod template : elle est la même pour les 4 révisions et ne modifie pas leur numérotation.
- **`readinessProbe` (httpGet `/` sur le port 80) sur tous les pods.** Un conteneur qui démarre puis plante en quelques millisecondes ne devient ainsi jamais prêt, ce qui rend l'état « indisponible » de `tie-fighter` stable. Elle rend aussi `rollout status` fiable pour les autres Deployments.
- **Pas de `kubectl rollout status` sur `death-star` avant la reprise** : je ne connais pas avec certitude son comportement sur un Deployment en pause (il pourrait attendre indéfiniment). L'étape 2 s'appuie sur `.spec.paused`, `get rs` et `rollout history`, dont le résultat est prévisible.
- **Vérifications orientées résultat** : stratégie, valeurs de `maxSurge` et `maxUnavailable`, valeur d'`APP_RELEASE`, rollout terminé, révision active. `step3-verify.sh` vérifie le contenu restauré (`APP_RELEASE=v2`, pas de `command`, aucun pod en `CrashLoopBackOff`), pas seulement un numéro de révision.
- **`wait-for-prep.sh` rétabli à ta demande**, sur le modèle du scénario MetalLB. Ce mécanisme avait été jugé peu fiable dans des scénarios précédents sans que la cause soit identifiée dans mes notes : si le problème se reproduit, `kubectl get deployments` (étape 1) et `kubectl get pods -l app=tie-fighter` (étape 3) permettent de vérifier l'état à la main.

## Tested on paper only — hypothèses à vérifier au premier passage

Je n'ai pas pu exécuter ce scénario contre un cluster Kubernetes. Ce qui a été testé : la syntaxe de tous les scripts (`bash -n`), et la validité YAML ainsi que le contenu des 6 manifestes générés par `intro-background.sh`, via un faux `kubectl`. Ce qui reste à vérifier :

- **Comportement du Deployment en pause** : une modification du pod template ne crée ni ReplicaSet ni révision tant que le rollout est en pause. Je m'appuie sur ma connaissance du contrôleur de Deployments et de la documentation Kubernetes ; je n'ai pas pu récupérer la page officielle (URL hors liste autorisée). À contrôler : `death-star` doit afficher une seule révision avant `rollout resume`, et deux après.
- **Colonne `CHANGE-CAUSE`** : j'attends que les libellés posés via l'annotation `kubernetes.io/change-cause` dans les manifestes appliqués apparaissent dans `kubectl rollout history deployment/tie-fighter`. Non vérifié ; sinon la colonne affichera `<none>` sans rien casser d'autre.
- **Rollback avec `Recreate`** : avec un seul réplica, `rollout undo` doit supprimer le pod en erreur puis créer un pod à partir du contenu de la révision 2, sans que la stratégie n'empêche le retour (le nouveau pod est sain, donc le rollout se termine). Non observé.
- **Numérotation après le rollback** : j'attends les révisions 1, 3, 4, 5 après `rollout undo --to-revision=2` (la 2 est renumérotée en 5). C'est le comportement documenté, déjà utilisé dans le scénario `workload-scheduling-basics`, mais je ne l'ai pas observé. `step3-verify.sh` exige une révision active supérieure ou égale à 5.
- **Pod en `CrashLoopBackOff`** : nginx avec `-c` vers un fichier inexistant doit sortir en erreur immédiatement, ce qui donne `Error` puis `CrashLoopBackOff` après quelques redémarrages (de l'ordre d'une minute). C'est ce que `wait-for-prep.sh` attend ; non observé.
- **Durée de la préparation** : de l'ordre de deux minutes attendues (attente séquentielle des révisions 1 à 3 de `tie-fighter`, pull de `nginx:alpine`, puis apparition du `CrashLoopBackOff`). Accès à Docker Hub supposé, comme dans les scénarios précédents.
- **Édition à froid de la stratégie** : passer de `Recreate` à `RollingUpdate` avec le bloc `rollingUpdate` dans le même `kubectl edit` que le changement de variable doit être accepté par l'API (validation connue : `rollingUpdate` interdit avec `Recreate`, pas dans l'autre sens). Non exécuté.
- **Syntaxes `kubectl`** : `kubectl exec deploy/death-star -- sh -c 'echo $APP_RELEASE'`, les `jsonpath` avec filtre `[?(@.name=="APP_RELEASE")]` et l'annotation `deployment\.kubernetes\.io/revision` sont écrits de mémoire et non exécutés.
- **Lien du `finish.md`** : URL canonique de la documentation des Deployments, non vérifiée par un fetch.
