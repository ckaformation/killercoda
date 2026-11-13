# Étape 2 — Une modification qui n'est jamais déployée

L'équipe a modifié la variable `APP_RELEASE` du Deployment `death-star` (de `v1` à `v2`), mais rien ne se passe : le pod n'est jamais remplacé. Le rollout de ce Deployment a été mis en pause avant la modification.

## 1. Comparer le spec et les pods en cours d'exécution

Valeur demandée dans le Deployment :

`kubectl get deployment death-star -o jsonpath='{.spec.template.spec.containers[0].env[0].value}'`{{exec}}

Valeur réellement utilisée par un pod en cours d'exécution :

`kubectl exec deploy/death-star -- sh -c 'echo $APP_RELEASE'`{{exec}}

Les deux valeurs diffèrent : la modification est enregistrée, mais pas déployée.

## 2. Observer les ReplicaSets et l'historique

`kubectl get rs -l app=death-star`{{exec}}

`kubectl rollout history deployment/death-star`{{exec}}

Il n'y a qu'un seul ReplicaSet et qu'une seule révision. Tant que le rollout est en pause, Kubernetes ne crée pas de nouveau ReplicaSet pour une modification du pod template : la révision 2 n'existera qu'une fois le rollout repris.

## 3. Confirmer la pause

`kubectl get deployment death-star -o jsonpath='{.spec.paused}'`{{exec}}

Tu dois voir `true`.

> La pause sert à regrouper plusieurs modifications (image, variables, ressources...) pour ne déclencher qu'**un seul** rollout au moment de la reprise.

## 4. Reprendre le rollout

`kubectl rollout resume deployment/death-star`{{exec}}

`kubectl rollout status deployment/death-star`{{exec}}

## 5. Constater que le rollout est débloqué

`kubectl get rs -l app=death-star`{{exec}}

Un nouveau ReplicaSet est apparu et porte le pod ; l'ancien est à 0.

`kubectl rollout history deployment/death-star`{{exec}}

La révision 2 existe maintenant.

`kubectl exec deploy/death-star -- sh -c 'echo $APP_RELEASE'`{{exec}}

Le pod utilise désormais la valeur `v2`.
