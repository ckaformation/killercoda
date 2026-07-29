# Étape 5 — Valider le cluster

## 1. Filet de sécurité : autoriser le scheduling sur le control-plane

Par défaut, un nœud control-plane porte un taint qui l'empêche de recevoir des charges applicatives classiques — les pods doivent normalement s'exécuter sur `node01`. On retire quand même ce taint par sécurité (par exemple si `node01` n'a pas pu rejoindre le cluster) :

`kubectl taint nodes --all node-role.kubernetes.io/control-plane-`{{exec}}

## 2. Déployer une application de test

`kubectl create deployment nginx-test --image=nginx`{{exec}}

## 3. Vérifier que le pod démarre correctement

`kubectl get pods -o wide`{{exec}}

Le pod `nginx-test` doit passer à l'état `Running`. Regarde la colonne `NODE` : il tourne normalement sur `node01`.

## 4. Exposer l'application (optionnel)

`kubectl expose deployment nginx-test --port=80 --type=NodePort`{{exec}}

`kubectl get svc nginx-test`{{exec}}

Félicitations : ton cluster Kubernetes à deux nœuds, créé from scratch avec kubeadm, fonctionne !
