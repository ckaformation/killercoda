# Étape 5 — Rollback du StatefulSet

## 1. Consulter l'historique

`kubectl rollout history statefulset/jedi-archive`{{exec}}

Deux révisions : la création (`100m`) et la modification du CPU request (`250m`).

## 2. Revenir en arrière

`kubectl rollout undo statefulset/jedi-archive`{{exec}}

## 3. Constater que rien ne se passe... encore une fois

`k get pod jedi-archive-0 -o jsonpath='{.spec.containers[0].resources.requests.cpu}'`{{exec}}

Toujours `250m`. Logique : `updateStrategy: OnDelete` s'applique à **tout** changement du template, y compris un rollback — ce n'est pas un cas particulier. Le nouveau (ancien) template est enregistré, mais il faut de nouveau supprimer le pod pour qu'il soit pris en compte.

## 4. Supprimer le pod pour appliquer le rollback

`kubectl delete pod jedi-archive-0`{{exec}}

`k get pods -l app=jedi-archive`{{exec}}

Attends que le nouveau `jedi-archive-0` soit `Running`.

## 5. Vérifier

`k get pod jedi-archive-0 -o jsonpath='{.spec.containers[0].resources.requests.cpu}'`{{exec}}

Doit être revenu à `100m` : le rollback est maintenant effectif.
