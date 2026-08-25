# Étape 1 — Identifier et supprimer le pod le plus prioritaire

## 1. Observer les deux pods

`k get pods -n rebellion -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priority,PRIORITYCLASS:.spec.priorityClassName`{{exec}}

En Kubernetes, **plus la valeur numérique de priorité est élevée, plus la priorité est haute**. Chaque `PriorityClass` porte une valeur :

`k get priorityclass`{{exec}}

## 2. Identifier le pod le plus prioritaire

Avec `level1 = 100` et `level2 = 1000`, le pod portant `priorityClassName: level2` — `rebel-commander` — est le plus prioritaire des deux.

## 3. Le supprimer

`kubectl delete pod rebel-commander -n rebellion`{{exec}}

## 4. Vérifier

`k get pods -n rebellion`{{exec}}

Seul `x-wing-pilot` (`level1`) doit rester.
