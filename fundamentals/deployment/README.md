# Scénario Killercoda — Deployment : ReplicaSet, scaling et mise à jour d'image

## Contenu

```
deployment-fundamentals/
├── index.json                   # backend kubernetes-kubeadm-1node, 3 étapes
├── intro.md                     # Deployment -> ReplicaSet -> pods, état désiré, réconciliation
├── intro-background.sh          # alias k uniquement
├── step1.md / step1-verify.sh   # k create deployment (3 réplicas), k get deploy,rs,pods, --show-labels, SELECTOR
├── step2.md / step2-verify.sh   # k scale (5), k delete pod, remplacement par le ReplicaSet
├── step3.md / step3-verify.sh   # k set image, rollout status, k get rs / pods
└── finish.md
```

## Choix effectués

- **Deployment `snowspeeder`**, image `nginx:alpine`, créé par l'élève avec un gabarit `<A_COMPLETER>` (nom, image, réplicas), comme dans les autres scénarios pédagogiques.
- **Comparaison des deux selectors à l'étape 1** (`k get deploy -o wide` puis `k get rs -o wide`) : le Deployment cherche `app=snowspeeder`, le ReplicaSet y ajoute `pod-template-hash`. Cela prépare l'étape 3, où deux ReplicaSets coexistent.
- **Étape 2 : `k scale`** pour passer à 5 réplicas. L'élève choisit lui-même le pod à supprimer. Le texte fait remarquer qu'il n'y a toujours qu'un seul ReplicaSet (le scaling ne change pas le pod template).
- **Étape 3 : le nom du container est lu avec un `jsonpath`** avant le `k set image`, plutôt que supposé : le texte ne le donne pas en dur. La nouvelle image proposée est `nginx:stable-alpine`, et `step3-verify.sh` accepte n'importe quelle image différente de `nginx:alpine`.
- **Vérification du remplacement du pod supprimé (étape 2)** : un script ne peut pas voir directement qu'un pod a été supprimé. `step2-verify.sh` compte les événements `SuccessfulCreate` du ReplicaSet : 3 au départ, 2 pour le scaling, au moins 1 pour le remplacement, soit au moins 6.
- **Pas de `wait-for-prep.sh`** : la préparation se limite à l'alias `k`.
- **Spoiler maîtrisé** : comme pour les autres scénarios pédagogiques, les valeurs attendues sont dans l'énoncé, mais l'élève tape lui-même les commandes.

## Tested on paper only — hypothèses à vérifier au premier passage

Je n'ai pas pu exécuter ce scénario contre un cluster. Ce qui a été testé : la syntaxe de tous les scripts (`bash -n`) et la logique des trois scripts de vérification, avec un faux `kubectl` (cas de succès et cas d'échec). Ce qui reste à vérifier :

- **Tag `nginx:stable-alpine`** : je crois qu'il existe sur Docker Hub, mais je ne l'ai pas vérifié. Si ce n'est pas le cas, le rollout de l'étape 3 resterait bloqué en `ImagePullBackOff`.
- **Nom du container créé par `k create deployment`** : attendu `nginx` (dérivé de l'image). Le texte n'en dépend pas, car l'élève le lit avec la commande de l'étape 3.
- **Syntaxes `kubectl`** : l'option `--replicas` de `k create deployment`, les colonnes `SELECTOR` de `k get deploy/rs -o wide`, `k get events --field-selector reason=SuccessfulCreate`, et les labels `app=snowspeeder` et `pod-template-hash` sont écrits de mémoire et non exécutés.
- **Événements `SuccessfulCreate`** : le script de l'étape 2 suppose qu'ils sont créés sur le ReplicaSet (`involvedObject.kind=ReplicaSet`), un par pod, et qu'ils sont encore conservés quand l'élève clique sur « Vérifier ». Si Kubernetes les regroupait, le compte pourrait être inférieur à 6 malgré un pod bien supprimé.
- **Durée du rollout de l'étape 3** : elle inclut le téléchargement de la nouvelle image sur le nœud. `step3-verify.sh` attend jusqu'à 90 s.
- **Accès à Docker Hub** depuis le nœud, comme dans les scénarios précédents.
- **Lien du `finish.md`** : URL canonique de la documentation des Deployments, non vérifiée par un fetch.
