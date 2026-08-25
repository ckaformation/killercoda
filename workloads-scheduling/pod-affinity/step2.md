# Étape 2 — Déplacer yoda et observer luke le suivre

## 1. Supprimer les deux pods

`kubectl delete pod yoda luke`{{exec}}

## 2. Éditer le fichier de yoda

`vi /root/yoda.yaml`{{exec}}

Change `nodeName: node01` en `nodeName: controlplane`.

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 3. Recréer yoda d'abord

L'ordre compte : l'affinité de `luke` a besoin qu'un pod `app=yoda` soit **déjà** présent sur un nœud pour pouvoir s'y placer.

`kubectl apply -f /root/yoda.yaml`{{exec}}

`kubectl wait --for=condition=Ready pod/yoda --timeout=60s`{{exec}}

## 4. Recréer luke

Son fichier `/root/luke.yaml` porte déjà l'affinité ajoutée à l'étape 1 — inutile d'y retoucher :

`kubectl apply -f /root/luke.yaml`{{exec}}

## 5. Vérifier

`k get pods -o wide`{{exec}}

`yoda` et `luke` doivent maintenant être tous les deux sur `controlplane` : on n'a rien changé à la configuration de `luke` à ce stade, seulement à celle de `yoda` — c'est bien son affinité, évaluée à nouveau au moment de sa recréation, qui l'a fait suivre `yoda` vers son nouvel emplacement.
