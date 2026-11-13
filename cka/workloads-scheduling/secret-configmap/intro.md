# Init containers, Secrets et ConfigMaps

Bienvenue ! Ce scénario porte sur trois briques très fréquemment combinées : un **init container** qui prépare des données avant que le conteneur principal ne démarre, un **Secret** monté en volume, et un **ConfigMap**.

## Ce qui est déjà en place

- Un Deployment, `death-star-plans`, avec :
  - un init container (`copy-credentials`) qui exécute `cp /credentials/* /config/` ;
  - un conteneur principal (`nginx`) ;
  - un Secret, `death-star-plans-credentials`, avec deux clés : `username` et `password`.
- **Ce Deployment est cassé** : le volume censé fournir le Secret à l'init container est monté sur `/tmp` au lieu de `/credentials`, l'endroit que la commande `cp` attend. Le pod est donc bloqué en échec d'initialisation.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Diagnostiquer puis corriger le `mountPath` pour que l'init container trouve enfin le Secret.
2. Ajouter une nouvelle clé au Secret — et comprendre pourquoi ça ne suffit pas : il faudra déclencher un rollout du Deployment.
3. Créer un ConfigMap et monter son contenu dans le conteneur `nginx`.

C'est parti !
