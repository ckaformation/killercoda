# Étape 1 — Joindre l'application par l'IP d'un pod

## 0. Attendre que l'application soit prête

`k rollout status deploy echo-base`{{exec}}

Si la commande répond `not found`, la préparation de l'environnement n'est pas terminée : attends quelques secondes et relance-la.

## 1. Observer les pods et leurs adresses IP

`k get pods -o wide`{{exec}}

Les 3 pods du Deployment `echo-base` ont chacun **leur propre adresse IP** (colonne `IP`). Ils sont tous sur `node01` : le taint du `controlplane` empêche d'y placer des pods ordinaires.

## 2. Appeler l'application sur l'IP d'un pod

Choisis l'un des pods et note son adresse IP. Complète ensuite la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` par cette adresse avant de l'exécuter) :

```
curl <A_COMPLETER>
```

Ça fonctionne : la page affiche notamment le nom du pod qui répond et son adresse IP.

## 3. Garder l'adresse pour plus tard

Complète la commande suivante (elle n'est pas cliquable : remplace `<A_COMPLETER>` par l'adresse IP du pod que tu viens d'appeler) :

```
echo <A_COMPLETER> > /root/pod-ip.txt
```

On s'en resservira à l'étape 3.

## Pourquoi ce n'est pas une solution durable

Appeler un pod par son IP fonctionne, mais :

- **l'IP d'un pod est éphémère** : un pod n'est jamais « réparé », il est **remplacé**. Si le pod meurt, est supprimé ou déplacé, le Deployment en crée un nouveau, avec une **nouvelle adresse IP**. Celui qui utilisait l'ancienne adresse n'a plus personne au bout du fil ;
- **il y a 3 pods, donc 3 adresses** : laquelle donner à un client ? Et que faire quand on passe de 3 à 5 réplicas ?

Il faudrait un point d'accès **stable** à l'application, qui sache quels pods existent à chaque instant et répartisse les appels entre eux. C'est exactement ce que fait un **Service**, que tu vas créer à l'étape suivante.
