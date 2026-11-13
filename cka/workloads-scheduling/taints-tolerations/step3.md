# Étape 3 — Taint NoExecute sur controlplane

## 1. Ajouter un second taint

Un nœud peut porter plusieurs taints simultanément, avec des clés différentes :

`kubectl taint nodes controlplane order66=active:NoExecute`{{exec}}

`k describe node controlplane | grep -A3 Taints`{{exec}}

## 2. Observer une différence de comportement avec NoSchedule

Pas besoin de `rollout restart` cette fois — regarde directement :

`k get pods -l app=millennium-falcon -o wide`{{exec}}

Les pods `millennium-falcon` qui étaient sur `controlplane` en ont été **évincés**, sans qu'on ait rien demandé explicitement. C'est toute la différence entre les deux effets :

- `NoSchedule` (étape 1) : bloque les **nouveaux** placements, mais ne touche pas aux pods déjà en place.
- `NoExecute` : **expulse** aussi les pods déjà en place s'ils ne tolèrent pas le taint — y compris ceux qui toléraient déjà `NoSchedule`, puisque `order66` est un taint distinct, avec sa propre toleration à part.

`k get pods -l app=x-wing-squadron -o wide`{{exec}}

`x-wing-squadron` n'a rien à voir avec `controlplane` depuis l'étape 1 : ce second taint ne change rien pour lui.
