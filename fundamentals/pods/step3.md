# Étape 3 — Container supprimé, pod supprimé : qui recrée quoi ?

Tu es toujours connecté à `node01`. Vérifie-le :

`hostname`{{exec}}

## 1. Supprimer le container avec crictl

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` avant de l'exécuter) :

```
crictl rm -f <A_COMPLETER>
```

Utilise l'identifiant du container de l'étape précédente (`cat /root/bb-8-container-id`). L'option `-f` force la suppression d'un container qui tourne.

## 2. Observer la réaction du kubelet

`crictl ps --name bb-8`{{exec}}

Un container nommé `bb-8` est de nouveau présent, mais avec un **autre identifiant** et une date de création récente : le kubelet a constaté que le container du pod avait disparu et en a recréé un. Si tu ne vois rien, attends quelques secondes et relance la commande.

Sauvegarde le nouvel identifiant :

`crictl ps --name bb-8 -q > /root/bb-8-new-container-id`{{exec}}

`cat /root/bb-8-new-container-id`{{exec}}

Le pod, lui, n'a pas changé :

`crictl pods --name bb-8`{{exec}}

Le `POD ID` est le même qu'à l'étape précédente : seul le container a été remplacé à l'intérieur du pod.

## 3. Retourner sur controlplane

`exit`{{exec}}

`hostname`{{exec}}

Tu dois voir `controlplane`.

`k get pod bb-8`{{exec}}

Le pod existe toujours et est `Running`. Pour Kubernetes, rien d'anormal : son container a été relancé par le kubelet, conformément à la politique de redémarrage du pod (`restartPolicy: Always` par défaut).

## 4. Supprimer le pod

`k delete pod bb-8`{{exec}}

`k get pods`{{exec}}

Le pod a disparu, et il ne revient pas. Attends une trentaine de secondes et relance la commande :

`k get pods`{{exec}}

Toujours rien. Côté `node01`, le kubelet a aussi arrêté le container du pod supprimé : `crictl ps` n'en affiche plus.

`ssh node01 crictl ps --name bb-8`{{exec}}

## Ce qu'il faut retenir

- Supprimer un **container** : le pod existe toujours, donc le **kubelet** le recrée.
- Supprimer le **pod** : l'objet disparaît de l'API, et personne n'est chargé de le recréer. Un pod créé avec `k run` n'a pas de contrôleur derrière lui.
- Pour qu'un pod supprimé soit recréé automatiquement, il faut un contrôleur, comme un **Deployment** (via un ReplicaSet).
