# Étape 1 — Corriger le mountPath de l'init container

## 1. Constater le problème

`k get pods -l app=death-star-plans`{{exec}}

Le pod est bloqué, quelque chose comme `Init:Error` ou `Init:CrashLoopBackOff`.

`k logs -l app=death-star-plans -c copy-credentials`{{exec}}

Tu devrais voir une erreur du type `cp: can't stat '/credentials/*': No such file or directory`.

## 2. Comprendre pourquoi

`k get deployment death-star-plans -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts}'`{{exec}}

Le volume `credentials` (celui qui vient du Secret) est monté sur `/tmp`, pas sur `/credentials` — l'endroit que la commande `cp /credentials/* /config/` de l'init container attend. Le Secret est bien là, juste au mauvais endroit.

## 3. Corriger

`kubectl edit deployment death-star-plans`{{exec}}

Dans `initContainers[0].volumeMounts`, repère l'entrée du volume `credentials` et change `mountPath: /tmp` en `mountPath: /credentials`.

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 4. Vérifier

`k get pods -l app=death-star-plans`{{exec}}

Le pod doit passer à `Running` (`2/2` — l'init container ne compte pas dans ce total une fois terminé, mais les 2 conteneurs de l'étape "ready" doivent l'être).

`POD=$(kubectl get pod -l app=death-star-plans -o jsonpath='{.items[0].metadata.name}') && kubectl exec "$POD" -c nginx -- cat /config/username`{{exec}}

Doit afficher `obi-wan` : l'init container a bien copié le contenu du Secret vers `/config`.
