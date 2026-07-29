# Étape 4 — Valider le cluster

## 1. Autoriser le scheduling sur le control-plane

Par défaut, un nœud control-plane porte un taint qui l'empêche de recevoir des charges applicatives classiques. Ce cluster n'ayant qu'un seul nœud, on retire ce taint pour pouvoir y déployer des pods :

`kubectl taint nodes --all node-role.kubernetes.io/control-plane-`{{exec}}

## 2. Déployer une application de test

`kubectl create deployment nginx-test --image=nginx`{{exec}}

## 3. Vérifier que le pod démarre correctement

`kubectl get pods -o wide`{{exec}}

Le pod `nginx-test` doit passer à l'état `Running`.

## 4. Exposer l'application (optionnel)

`kubectl expose deployment nginx-test --port=80 --type=NodePort`{{exec}}

`kubectl get svc nginx-test`{{exec}}

Félicitations : ton cluster Kubernetes, créé from scratch avec kubeadm, fonctionne !
