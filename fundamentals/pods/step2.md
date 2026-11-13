# Étape 2 — Où tourne le pod ? Le retrouver côté runtime avec crictl

## 1. Sur quel node le pod a-t-il été placé ?

`k get pod bb-8 -o wide`{{exec}}

La colonne `NODE` indique `node01`, le worker. Pourquoi pas `controlplane` ?

`k get nodes`{{exec}}

Les deux nodes sont `Ready`, donc `controlplane` aurait pu accueillir le pod. Regarde ses **taints** :

`k describe node controlplane | grep Taints`{{exec}}

Le taint `node-role.kubernetes.io/control-plane:NoSchedule` **repousse** les pods qui ne le tolèrent pas : le scheduler ne place pas de pod ordinaire sur ce node. Le pod `bb-8` n'a pas de toleration pour ce taint, il n'a que les tolerations ajoutées automatiquement par Kubernetes :

`k get pod bb-8 -o jsonpath='{.spec.tolerations}'`{{exec}}

## 2. Se connecter au node qui héberge le pod

Un pod est une notion Kubernetes, mais ses containers tournent bien sur une machine réelle. Connecte-toi à `node01` :

`ssh node01`{{exec}}

Si `ssh` te demande de confirmer l'empreinte du serveur, réponds `yes`.

`hostname`{{exec}}

Tu dois voir `node01`. Toutes les commandes suivantes de cette étape s'exécutent sur ce node.

## 3. Retrouver le pod et son container avec crictl

`crictl` parle directement à containerd, sans passer par l'API Kubernetes. Il ne connaît ni les Deployments ni les namespaces comme `kubectl` : il voit des **pods** (en fait leur *sandbox*, l'environnement réseau partagé du pod) et des **containers**.

`crictl pods --name bb-8`{{exec}}

Le pod `bb-8` apparaît avec son identifiant (`POD ID`). Note-le.

`crictl ps --name bb-8`{{exec}}

Le container `bb-8` apparaît avec son identifiant (`CONTAINER`) et le `POD ID` du pod auquel il appartient. Si tu ne vois rien, vérifie que tu es bien sur `node01`.

Sauvegarde l'identifiant complet du container dans un fichier, pour le comparer à l'étape suivante :

`crictl ps --name bb-8 -q > /root/bb-8-container-id`{{exec}}

`cat /root/bb-8-container-id`{{exec}}

## 4. Lire les logs du container avec crictl

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` avant de l'exécuter) :

```
crictl logs <A_COMPLETER>
```

Utilise l'identifiant du container, c'est-à-dire le contenu du fichier que tu viens d'afficher.

Tu retrouves les mêmes lignes que dans `k logs bb-8` : quand tu lances `k logs`, c'est le kubelet de ce node qui lit les logs du container pour te les renvoyer.

> Reste connecté à `node01` pour l'étape suivante.
