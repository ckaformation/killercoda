# Étape 2 — Saturer les deux nœuds avec le label app=yoda

## 1. Copier la définition de yoda

`cp /root/yoda.yaml /root/yoda-2.yaml`{{exec}}

`vi /root/yoda-2.yaml`{{exec}}

Deux changements, et un seul :

- `metadata.name: yoda` → `yoda-2`
- `spec.nodeName: node01` → `controlplane`

**Ne touche pas** à `labels.app: yoda` — c'est justement le point.

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 2. Déployer yoda-2

`kubectl apply -f /root/yoda-2.yaml`{{exec}}

`k get pods -o wide --show-labels`{{exec}}

Les deux nœuds portent maintenant chacun un pod `app=yoda`.

## 3. Constater que luke ne bouge pas tout seul

`k get pod luke -o wide`{{exec}}

`luke` tourne toujours tranquillement sur `controlplane`, alors qu'il devrait désormais l'éviter. Rien d'anormal : `IgnoredDuringExecution` (dans le nom du champ) signifie que la contrainte n'est vérifiée **qu'au moment du scheduling** — un pod déjà en place n'est jamais réévalué ni évincé après coup, même s'il viole une règle qui s'appliquerait à une nouvelle tentative de placement.

## 4. Forcer une nouvelle décision de scheduling

`kubectl delete pod luke`{{exec}}

`kubectl apply -f /root/luke.yaml`{{exec}}

## 5. Observer le blocage

`k get pod luke -o wide`{{exec}}

`luke` doit rester à l'état `Pending` : aucun des deux nœuds ne satisfait plus sa contrainte, puisque `app=yoda` est désormais présent partout.

`kubectl describe pod luke`{{exec}}

Dans la section `Events`, tu devrais voir une raison explicite de type "didn't match pod anti-affinity rules" pour les deux nœuds.
