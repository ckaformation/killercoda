# Étape 2 — Rollback sur blue

Un bug est signalé sur la version green : il faut renvoyer tout le trafic vers blue, tout de suite.

## 1. Rebasculer le Service sur blue

`kubectl patch service lightsaber -p '{"spec":{"selector":{"version":"blue"}}}'`{{exec}}

## 2. Vérifier le retour arrière

`kubectl get svc lightsaber -o wide`{{exec}}

Le selector vaut de nouveau `app=lightsaber,version=blue`.

`kubectl get endpointslices -l kubernetes.io/service-name=lightsaber`{{exec}}

Les IP de la colonne `ENDPOINTS` sont celles des pods blue :

`kubectl get pods -l version=blue -o wide`{{exec}}

Appelle le Service plusieurs fois :

```
for i in $(seq 1 6); do curl -s http://jedi-temple:30080; done
```{{exec}}

Chaque réponse doit être `Sabre laser - version blue`.

## 3. Comprendre pourquoi c'est immédiat

`kubectl get pods -L version`{{exec}}

La colonne `AGE` le montre : aucun pod n'a été recréé. Les pods blue tournaient toujours, seul le selector du Service a changé.

> À l'inverse, `kubectl rollout undo` crée de nouveaux pods à partir d'une ancienne révision : le retour arrière prend le temps d'un rollout. Le blue/green évite cette attente, au prix de deux versions qui tournent en même temps (donc deux fois plus de ressources).

La version green reste en place : tu vas la tester à l'étape suivante.
