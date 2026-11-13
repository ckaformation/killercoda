# Étape 5 — Atteindre le Service depuis les nodes avec un NodePort

Une `CLUSTER-IP` est une adresse **interne** au cluster. Pour qu'un Service soit joignable via l'adresse d'un node, on utilise le type `NodePort` : Kubernetes ouvre le même port sur **tous** les nodes du cluster et redirige le trafic vers le Service.

## 1. Transformer le Service en NodePort

`k edit svc echo-base`{{exec}}

Fais **deux** modifications.

**Modification n°1** : dans `spec.ports`, ajoute la ligne `nodePort: 30080` sur l'entrée du port :

```
spec:
  ports:
  - nodePort: 30080
    port: 80
    protocol: TCP
    targetPort: 80
```

**Modification n°2** : en bas du `spec`, change `type: ClusterIP` en `type: NodePort` :

```
  type: NodePort
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

> Un `NodePort` est choisi par défaut dans la plage 30000-32767. Ici, on le fixe à `30080` pour que tout le monde utilise la même valeur.

`k get svc echo-base`{{exec}}

Le type est maintenant `NodePort`, et la colonne `PORT(S)` affiche `80:30080/TCP` : le port 80 du Service est joignable sur le port 30080 de chaque node. Le Service garde aussi sa `CLUSTER-IP` : un NodePort s'ajoute à un ClusterIP, il ne le remplace pas.

## 2. Récupérer les adresses des nodes

`k get nodes -o wide`{{exec}}

Note l'`INTERNAL-IP` de `controlplane` et celle de `node01`.

## 3. Appeler le Service sur l'IP de controlplane

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` par l'`INTERNAL-IP` de `controlplane`) :

```
curl <A_COMPLETER>:30080
```

## 4. Appeler le Service sur l'IP de node01

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` par l'`INTERNAL-IP` de `node01`) :

```
curl <A_COMPLETER>:30080
```

## 5. Comprendre ce que tu viens de constater

Les deux appels fonctionnent. Pourtant, les pods d'`echo-base` ne sont que sur `node01` :

`k get pods -o wide`{{exec}}

Le port 30080 est ouvert sur **chaque** node, même sur ceux qui n'hébergent aucun pod de l'application, comme `controlplane` : le trafic reçu est redirigé vers l'un des pods du Service, où qu'il soit dans le cluster. Tu peux donc joindre l'application en passant par l'adresse de n'importe quel node.
