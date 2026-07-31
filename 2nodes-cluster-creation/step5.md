# Étape 5 — Valider le cluster

## 1. Déployer une application de test

`kubectl create deployment nginx-test --image=nginx`{{exec}}

## 2. Vérifier que le pod démarre correctement

`watch kubectl get pods -o wide`{{exec}}

Attends que le pod `nginx-test` passe à l'état `Running`, puis quitte avec `Ctrl+C`. Regarde la colonne `NODE` : il tourne sur `node01`, le seul nœud du cluster à pouvoir accueillir des charges applicatives classiques (`controlplane` conserve son taint par défaut).

## 3. Exposer l'application

`kubectl expose deployment nginx-test --port=80 --type=NodePort`{{exec}}

`kubectl get svc nginx-test`{{exec}}

## 4. Valider que le service répond

Un service `NodePort` ouvre en principe le même port sur **tous** les nœuds du cluster, quel que soit celui qui héberge réellement le pod. Sur cet environnement, cibler `localhost` depuis `controlplane` ne fonctionne pas (`connection refused`) ; cibler directement `node01` — le nœud qui héberge réellement le pod — fonctionne. La cause exacte n'est pas confirmée (probablement lié à la façon dont `kube-proxy`/l'overlay Calico gèrent ici le NodePort), donc on reste pragmatique et on cible `node01`.

On s'assure d'abord que le pod est bien `Ready` (tant qu'il ne l'est pas, le service n'a aucun endpoint et la connexion est refusée) :

`kubectl wait --for=condition=Ready pod -l app=nginx-test --timeout=60s`{{exec}}

Puis on teste le service, depuis `controlplane`, en ciblant `node01` :

`curl -s -o /dev/null -w "%{http_code}\n" http://node01:$(kubectl get svc nginx-test -o jsonpath='{.spec.ports[0].nodePort}')`{{exec}}

Si tu obtiens `200`, le pod `nginx` répond correctement.

Félicitations : ton cluster Kubernetes à deux nœuds, créé from scratch avec kubeadm, fonctionne !
