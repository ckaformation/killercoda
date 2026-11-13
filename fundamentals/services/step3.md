# Étape 3 — Supprimer un pod : le Service continue de répondre

Le Deployment `echo-base` a 3 réplicas depuis le début. À l'étape 1, tu as enregistré l'IP d'un pod dans `/root/pod-ip.txt` : c'est ce pod que tu vas supprimer.

## 1. Retrouver le pod

`k get pods -o wide | grep $(cat /root/pod-ip.txt)`{{exec}}

La première colonne est le nom du pod dont l'IP est dans le fichier.

## 2. Supprimer ce pod

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` par le nom du pod) :

```
k delete pod <A_COMPLETER>
```

## 3. Constater que le Deployment a remplacé le pod

`k get pods -o wide`{{exec}}

Il y a toujours 3 pods : le Deployment en a créé un nouveau pour remplacer celui que tu as supprimé. Il a un **autre nom** et une **autre adresse IP**.

## 4. Constater que l'ancienne IP ne répond plus

`curl --max-time 3 $(cat /root/pod-ip.txt)`{{exec}}

La commande échoue (erreur de connexion ou délai dépassé) : cette adresse n'existe plus. Un client qui l'aurait utilisée serait en panne.

## 5. Constater que le Service, lui, répond toujours

`curl $(k get svc echo-base -o jsonpath='{.spec.clusterIP}')`{{exec}}

La `CLUSTER-IP` n'a pas changé, et le Service répond : il n'y a rien à reconfigurer côté client.

`k describe svc echo-base`{{exec}}

Regarde la ligne `Endpoints` : l'adresse du pod supprimé n'y figure plus, et celle du nouveau pod y a été ajoutée automatiquement. Le Service ne suit pas des pods précis, il suit des **labels** : tout pod portant `app=echo-base` et prêt devient un endpoint.
