# Étape 1 — Déployer le StatefulSet de l'opérateur

## 1. Examiner ce qui est déjà en place

`k get sa,clusterrole,clusterrolebinding -n operators`{{exec}}

`k get clusterrole namespace-operator-role -o yaml`{{exec}}

Note bien les verbes autorisés sur `namespaces` : `get`, `list`, `create` — pas `patch`. On y reviendra à l'étape 4.

## 2. Examiner le StatefulSet à déployer

`cat /root/operator/statefulset.yaml`{{exec}}

Deux objets dans ce fichier :

- un `Service` headless (`clusterIP: None`) : requis par tout `StatefulSet`, pour l'identité réseau stable de ses pods (même si notre opérateur ne l'exploite pas vraiment ici) ;
- le `StatefulSet` lui-même, avec le script shell de l'opérateur intégré. Repère le commentaire `# TODO` : c'est là qu'on ajoutera la labellisation à l'étape 4.

## 3. Déployer

`kubectl apply -f /root/operator/statefulset.yaml`{{exec}}

## 4. Vérifier

`k get statefulset -n operators`{{exec}}

`k get pods -n operators`{{exec}}

Le pod doit passer à l'état `Running`.

`k logs -n operators namespace-operator-0`{{exec}}

Tu devrais voir le message de démarrage. Pour l'instant, l'opérateur ne fait rien de plus : la CRD `NamespaceSet` n'existe pas encore.
