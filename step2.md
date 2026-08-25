# Étape 2 — Déplacer yoda et observer luke le suivre

## 1. Tenter un edit direct sur yoda

`kubectl edit pod yoda`{{exec}}

Essaie de changer `nodeName: node01` en `nodeName: controlplane`.

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

Tu devrais obtenir une erreur : l'API server refuse la modification, avec un message du type `Forbidden: pod updates may not change fields other than ...`. Quitte sans réessayer (`Échap` puis `:q!` puis `Entrée` si l'éditeur se rouvre).

## 2. Comprendre pourquoi

`spec.nodeName`, comme `spec.affinity`, fait partie des champs qu'on ne peut plus modifier une fois le pod créé — un pod nu est très majoritairement immuable. Il faut le supprimer et le recréer avec la nouvelle spec.

## 3. Supprimer les deux pods

`kubectl delete pod yoda luke`{{exec}}

## 4. Éditer le fichier de yoda

`vi /root/yoda.yaml`{{exec}}

Change `nodeName: node01` en `nodeName: controlplane`.

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 5. Recréer yoda d'abord

L'ordre compte : l'affinité de `luke` a besoin qu'un pod `app=yoda` soit **déjà** présent sur un nœud pour pouvoir s'y placer.

`kubectl apply -f /root/yoda.yaml`{{exec}}

`kubectl wait --for=condition=Ready pod/yoda --timeout=60s`{{exec}}

## 6. Recréer luke

Son fichier `/root/luke.yaml` porte déjà l'affinité ajoutée à l'étape 1 — inutile d'y retoucher :

`kubectl apply -f /root/luke.yaml`{{exec}}

## 7. Vérifier

`k get pods -o wide`{{exec}}

`yoda` et `luke` doivent maintenant être tous les deux sur `controlplane` : on n'a rien changé à la configuration de `luke` à ce stade, seulement à celle de `yoda` — c'est bien son affinité, évaluée à nouveau au moment de sa recréation, qui l'a fait suivre `yoda` vers son nouvel emplacement.
