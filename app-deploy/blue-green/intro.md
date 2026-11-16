# Blue/Green : basculer le trafic entre deux versions

Bienvenue ! En **blue/green**, deux versions complètes d'une application tournent en même temps. Le trafic n'est envoyé que vers l'une d'elles, et on bascule d'une version à l'autre en changeant simplement le **selector** du Service : pas de rollout, pas de pod recréé, et un retour arrière immédiat.

## Ce qui est déjà en place

Un cluster Kubernetes mono-nœud, avec dans le namespace `default` :

| Objet | Détail |
|---|---|
| Deployment `lightsaber-blue` | 2 réplicas, labels `app=lightsaber`, `version=blue` |
| Deployment `lightsaber-green` | 2 réplicas, labels `app=lightsaber`, `version=green` |
| Service `lightsaber` | type `NodePort` (port `30080`), selector `app=lightsaber,version=blue` |

Les deux versions utilisent `nginx:alpine` et affichent leur version quand on les appelle.

Le nom `jedi-temple` a été ajouté dans `/etc/hosts` : il pointe vers l'IP du nœud. `curl http://jedi-temple:30080` appelle donc le Service par son NodePort.

Un raccourci `k` (identique à `kubectl`) est aussi disponible.

## Ce que tu vas faire

1. Basculer le trafic du Service `lightsaber` sur la version green, puis vérifier avec `curl`.
2. Revenir sur la version blue (rollback), puis vérifier avec `curl`.
3. Créer un Service `ClusterIP` pour tester la version green depuis l'intérieur du cluster, sans toucher au trafic public.

C'est parti !
