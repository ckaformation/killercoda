# Scénario Killercoda — Rollouts : stratégie, pause/reprise et rollback

## Contenu

```
rollout-deployments/
├── index.json                   # backend kubernetes-kubeadm-1node, 3 étapes
├── intro.md
├── intro-background.sh          # alias k + 3 Deployments (namespace default)
├── step1.md / step1-verify.sh   # millennium-falcon : Recreate -> RollingUpdate (1 / 0) + changement d'APP_RELEASE + rollout status
├── step2.md / step2-verify.sh   # death-star : rollout en pause -> rollout resume
├── step3.md / step3-verify.sh   # tie-fighter : 4 révisions, la 4e défectueuse -> rollout undo --to-revision=2
└── finish.md
```

## Préparation (intro-background.sh)

| Deployment | Réplicas | État initial |
|---|---|---|
| `millennium-falcon` | 2 | `nginx:alpine`, `APP_RELEASE="v2"`, stratégie `Recreate` |
| `death-star` | 2 | déployé en `APP_RELEASE="v1"`, rollout terminé, puis **mis en pause**, puis modifié en `APP_RELEASE="v2"` |
| `tie-fighter` | 2 | révisions 1 (initial, v1), 2 (v2 config changes), 3 (v3 rollout), 4 (v3 hotfix : `command: ["nginx","-c","/etc/nginx/hotfix.conf"]`, fichier inexistant) |

Les libellés des révisions de `tie-fighter` sont posés avec l'annotation `kubernetes.io/change-cause` dans chaque manifeste appliqué.

## Écart avec la demande initiale

La demande disait que `death-star` « a subi une modif qui a généré une 2ème révision mais que le rollout ne se fait pas ». Telle quelle, cette phrase ne correspond pas au comportement attendu d'un Deployment en pause : tant qu'il est en pause, une modification du pod template est enregistrée dans le spec, mais aucun nouveau ReplicaSet (donc aucune nouvelle révision) n'est créé. La révision 2 apparaît au `rollout resume`. Le scénario est écrit dans ce sens : l'étape 2 fait constater une seule révision avant la reprise, et deux après.

## Choix effectués

- **Noms Star Wars** pour les Deployments, tous dans `default` comme demandé.
- **`readinessProbe` (httpGet `/` sur le port 80) sur tous les pods.** Sans elle, le pod défectueux de la révision 4 pourrait être compté brièvement comme prêt avant de planter, et le rollout pourrait alors arrêter les anciens pods sains (`maxUnavailable` à 0 ne protège que tant que le nouveau pod n'est pas disponible). Avec elle, un conteneur qui plante en quelques millisecondes ne devient jamais prêt.
- **Deux pods sains + un pod en erreur pour `tie-fighter`** : avec 2 réplicas et les valeurs par défaut de la stratégie (25 % / 25 %), `maxSurge` s'arrondit à 1 (arrondi supérieur) et `maxUnavailable` à 0 (arrondi inférieur). Le rollout de la révision 4 crée donc 1 pod supplémentaire, qui plante, et garde les 2 pods de la révision 3 en service.
- **Pas de `kubectl rollout status` sur `death-star` avant la reprise** : je ne connais pas avec certitude son comportement sur un Deployment en pause (il pourrait attendre indéfiniment). L'étape 2 s'appuie sur `.spec.paused`, `get rs` et `rollout history`, dont le résultat est prévisible.
- **Vérifications orientées résultat** : stratégie, valeurs de `maxSurge` et `maxUnavailable`, valeur d'`APP_RELEASE`, rollout terminé, révision active. `step3-verify.sh` vérifie le contenu restauré (`APP_RELEASE=v2`, pas de `command`, aucun pod en `CrashLoopBackOff`), pas seulement un numéro de révision.
- **Pas de `wait-for-prep.sh`** (jugé peu fiable) : l'étape 1 commence par `kubectl get deployments`, et l'étape 3 invite à patienter si le pod en erreur n'est pas encore visible.

## Tested on paper only — hypothèses à vérifier au premier passage

Je n'ai pas pu exécuter ce scénario contre un cluster Kubernetes. Ce qui a été testé : la syntaxe de tous les scripts (`bash -n`), et la validité YAML ainsi que le contenu des 6 manifestes générés par `intro-background.sh`, via un faux `kubectl`. Ce qui reste à vérifier :

- **Comportement du Deployment en pause** : une modification du pod template ne crée ni ReplicaSet ni révision tant que le rollout est en pause. Je m'appuie sur ma connaissance du contrôleur de Deployments et de la documentation Kubernetes ; je n'ai pas pu récupérer la page officielle (URL hors liste autorisée). À contrôler : `death-star` doit afficher une seule révision avant `rollout resume`, et deux après.
- **Colonne `CHANGE-CAUSE`** : j'attends que les libellés posés via l'annotation `kubernetes.io/change-cause` dans les manifestes appliqués apparaissent dans `kubectl rollout history deployment/tie-fighter`. Non vérifié ; sinon la colonne affichera `<none>` sans rien casser d'autre.
- **Numérotation après le rollback** : j'attends les révisions 1, 3, 4, 5 après `rollout undo --to-revision=2` (la 2 est renumérotée en 5). C'est le comportement documenté, déjà utilisé dans le scénario `workload-scheduling-basics`, mais je ne l'ai pas observé. `step3-verify.sh` exige une révision active supérieure ou égale à 5.
- **Pod en `CrashLoopBackOff`** : nginx avec `-c` vers un fichier inexistant doit sortir en erreur immédiatement, ce qui donne `Error` puis `CrashLoopBackOff` après quelques redémarrages (de l'ordre d'une minute). L'étape 3 prévoit qu'un pod en `Error` ou pas encore listé est normal au début.
- **Durée de la préparation** : environ une minute attendue (attente séquentielle des révisions 1 à 3 de `tie-fighter`, pull de `nginx:alpine`). Accès à Docker Hub supposé, comme dans les scénarios précédents.
- **Syntaxes `kubectl`** : `kubectl exec deploy/death-star -- sh -c 'echo $APP_RELEASE'`, les `jsonpath` avec filtre `[?(@.name=="APP_RELEASE")]` et l'annotation `deployment\.kubernetes\.io/revision` sont écrits de mémoire et non exécutés.
- **Lien du `finish.md`** : URL canonique de la documentation des Deployments, non vérifiée par un fetch.
