# Étape 1 — Diagnostiquer puis corriger les droits RBAC

## Contexte

Le CronJob `nettoyeur`, dans le namespace `ops`, est censé supprimer les pods à l'état `Completed` — mais il échoue : le ServiceAccount qu'il utilise, `leon`, n'a pas les droits nécessaires.

## 1. Observer l'état actuel

`k get cronjob nettoyeur -n ops`{{exec}}

`k get pods -n ops`{{exec}}

Tu devrais voir trois pods `pod-a-nettoyer-*` à l'état `Completed` : ce sont eux que le CronJob est censé supprimer.

`k get jobs -n ops`{{exec}}

> Le CronJob est planifié toutes les minutes. S'il s'est déjà déclenché au moins une fois, tu verras un ou plusieurs Jobs en échec ci-dessus. Sinon, patiente une minute ou passe directement au point 2.

Si un Job existe déjà, regarde ses logs :

`k logs -n ops -l job-name --tail=20`{{exec}}

Tu devrais y voir une erreur du type `pods is forbidden: User "system:serviceaccount:ops:leon" cannot list resource "pods"`.

## 2. Confirmer le diagnostic avec kubectl auth can-i

Un ServiceAccount s'usurpe avec la syntaxe `system:serviceaccount:<namespace>:<nom>` :

`k auth can-i list pods --as=system:serviceaccount:ops:leon -n ops`{{exec}}

`k auth can-i delete pods --as=system:serviceaccount:ops:leon -n ops`{{exec}}

Les deux doivent répondre `no`.

## 3. Créer le Role et le RoleBinding

`leon` a besoin de lister et de supprimer des pods, dans le namespace `ops` uniquement :

`k create role ops-pod-cleaner --verb=get,list,delete --resource=pods -n ops`{{exec}}

`k create rolebinding leon-ops-pod-cleaner --role=ops-pod-cleaner --serviceaccount=ops:leon -n ops`{{exec}}

## 4. Vérifier

`k auth can-i list pods --as=system:serviceaccount:ops:leon -n ops`{{exec}}

`k auth can-i delete pods --as=system:serviceaccount:ops:leon -n ops`{{exec}}

Les deux doivent maintenant répondre `yes`.

## 5. Vérifier que le nettoyage automatique fonctionne

`leon` a maintenant les droits nécessaires : au prochain déclenchement planifié du CronJob (au plus tard dans la minute qui vient), les pods `Completed` du namespace `ops` devraient être supprimés automatiquement, sans aucune action supplémentaire de ta part.

`watch kubectl get pods -n ops`{{exec}}

Patiente jusqu'à ce que `pod-a-nettoyer-1`, `pod-a-nettoyer-2` et `pod-a-nettoyer-3` disparaissent de la liste, puis quitte avec `Ctrl+C`.

`k get jobs -n ops`{{exec}}

Le Job le plus récent doit maintenant afficher `1/1` dans la colonne `COMPLETIONS`.
