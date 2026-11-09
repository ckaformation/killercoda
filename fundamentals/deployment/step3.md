# Étape 3 — Mettre à jour l'image et observer le nouveau ReplicaSet

Changer le **nombre** de réplicas ne touche pas au modèle de pod. Changer l'**image**, si : c'est une nouvelle version de l'application.

## 1. Retrouver le nom du container

`k set image` a besoin du nom du **container** à modifier, pas seulement du nom du Deployment :

`k get deploy snowspeeder -o jsonpath='{.spec.template.spec.containers[0].name}'`{{exec}}

## 2. Mettre à jour l'image

Complète la commande suivante (elle n'est pas cliquable : remplace chaque `<A_COMPLETER>` avant de l'exécuter) :

```
k set image deploy snowspeeder <A_COMPLETER>=<A_COMPLETER>
```

Le premier `<A_COMPLETER>` est le nom du container affiché ci-dessus ; le second est la nouvelle image : utilise `nginx:stable-alpine`.

## 3. Suivre le déploiement

`k rollout status deploy snowspeeder`{{exec}}

Cette commande affiche la progression : les anciens pods sont remplacés **progressivement** par des pods utilisant la nouvelle image, de façon à garder l'application disponible pendant la mise à jour (stratégie `RollingUpdate`, par défaut). Elle rend la main quand tous les pods ont été remplacés.

## 4. Observer le nouveau ReplicaSet

`k get rs -o wide`{{exec}}

Il y a maintenant **deux ReplicaSets** :

- l'ancien, avec l'image `nginx:alpine`, à `0` réplica : il est conservé (avec son modèle de pod) pour permettre un retour en arrière ;
- le nouveau, avec la nouvelle image, qui porte désormais les 5 pods.

Le nouveau ReplicaSet a son propre hash, donc son propre `pod-template-hash` dans son selector. C'est ce qui permet aux deux ReplicaSets de coexister sans se « voler » des pods.

## 5. Observer les nouveaux pods

`k get pods --show-labels`{{exec}}

Les 5 pods sont tous nouveaux : leur nom commence par le nom du **nouveau** ReplicaSet, et leur label `pod-template-hash` a changé.

`k rollout history deploy snowspeeder`{{exec}}

Le Deployment a maintenant deux révisions : la création, puis la mise à jour de l'image.
