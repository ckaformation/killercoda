# Probes : readiness et liveness

Bienvenue sur Hoth ! Un conteneur qui tourne n'est pas forcément un conteneur qui fonctionne. Les **probes** permettent au kubelet de vérifier régulièrement la santé d'un conteneur et d'agir en conséquence. Dans ce scénario, tu ajoutes une `readinessProbe` et une `livenessProbe` à une application, puis tu observes ce qui se passe quand la liveness échoue.

## Ce qui est déjà en place

Un cluster Kubernetes mono-nœud, avec dans le namespace `hoth` le Deployment `echo-base` : 1 réplica, image `nginx:alpine`, **aucune probe**. Son manifeste est dans `/root/echo-base.yaml`.

Au démarrage, le conteneur :

- crée le fichier `/tmp/life-signs` ;
- publie une page `/healthz` sur le port 80 ;
- lance nginx.

Un raccourci `k` (identique à `kubectl`) est aussi disponible.

## Ce que tu vas faire

1. Ajouter une `readinessProbe` HTTP sur `/healthz`.
2. Ajouter une `livenessProbe` qui vérifie la présence de `/tmp/life-signs`.
3. Supprimer `/tmp/life-signs` et observer la réaction du kubelet.

C'est parti !
