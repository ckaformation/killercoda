# Étape 1 — Diagnostiquer puis corriger les droits RBAC

## Contexte

Le CronJob `nettoyeur`, dans le namespace `ops`, est censé supprimer les pods à l'état `Completed` — mais il échoue : le ServiceAccount qu'il utilise, `leon`, n'a pas les droits nécessaires.

## 1. Observer l'état actuel

`k get cronjob nettoyeur -n ops`{{exec}}

> La colonne `SUSPEND` affiche `True` : c'est volontaire. Le CronJob est mis en pause dès sa création pour que sa planification (`*/1 * * * *`) ne se déclenche jamais automatiquement — dans ce scénario, seul un déclenchement manuel doit lancer le nettoyage (ce sera l'objet de l'étape 2). Une première tentative a tout de même déjà eu lieu, créée pour toi une seule fois au démarrage du scénario : c'est celle qu'on va diagnostiquer.

`k get pods -n ops`{{exec}}

Tu devrais voir trois pods `pod-a-nettoyer-*` à l'état `Completed` : ce sont eux que le CronJob est censé supprimer.

`k get jobs -n ops`{{exec}}

Le Job `nettoyeur-auto-1` doit apparaître en échec (`0/1` dans `COMPLETIONS`). Regarde ses logs :

`k logs -n ops -l job-name=nettoyeur-auto-1 --tail=20`{{exec}}

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
