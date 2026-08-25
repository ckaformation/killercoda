# Étape 2 — Tolérer le taint NoSchedule

## 1. Modifier millennium-falcon

`kubectl edit deployment millennium-falcon`{{exec}}

Dans `spec.template.spec`, ajoute une section `tolerations` (au même niveau que `containers`) :

```yaml
tolerations:
  - key: "empire"
    operator: "Equal"
    value: "occupied"
    effect: "NoSchedule"
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 2. Vérifier

`kubectl rollout status deployment/millennium-falcon`{{exec}}

`k get pods -l app=millennium-falcon -o wide`{{exec}}

Ses pods peuvent désormais se poser sur `controlplane` — plus rien ne les en empêche.

`k get pods -l app=x-wing-squadron -o wide`{{exec}}

`x-wing-squadron`, lui, n'a pas été touché : ses pods restent forcément sur `node01`, seul nœud qu'il tolère encore.
