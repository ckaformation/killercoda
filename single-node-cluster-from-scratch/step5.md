# Étape 5 — Valider le cluster

## 1. Déployer une application de test

`kubectl create deployment nginx-test --image=nginx`{{exec}}

## 2. Vérifier que le pod démarre correctement

`kubectl get pods -o wide`{{exec}}

Le pod `nginx-test` doit passer à l'état `Running`. Regarde la colonne `NODE` : il tourne sur `node01`, le seul nœud du cluster à pouvoir accueillir des charges applicatives classiques (`controlplane` conserve son taint par défaut).

## 3. Exposer l'application

`kubectl expose deployment nginx-test --port=80 --type=NodePort`{{exec}}

`kubectl get svc nginx-test`{{exec}}

## 4. Valider que le service répond

Un service `NodePort` ouvre le même port sur **tous** les nœuds du cluster, quel que soit celui qui héberge réellement le pod — le routage est assuré par `kube-proxy`. On peut donc le tester directement depuis `controlplane`, sans avoir à se soucier de savoir où tourne le pod :

`curl -s -o /dev/null -w "%{http_code}\n" http://localhost:$(kubectl get svc nginx-test -o jsonpath='{.spec.ports[0].nodePort}')`{{exec}}

Si tu obtiens `200`, le service NodePort route correctement le trafic jusqu'au pod `nginx` exécuté sur `node01`.

Félicitations : ton cluster Kubernetes à deux nœuds, créé from scratch avec kubeadm, fonctionne !
