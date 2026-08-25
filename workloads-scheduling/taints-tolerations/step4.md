# Étape 4 — Tolérer le taint NoExecute

## 1. Modifier de nouveau millennium-falcon

`kubectl edit deployment millennium-falcon`{{exec}}

Ajoute une seconde entrée dans `tolerations`, à côté de celle de l'étape 2 :

```yaml
tolerations:
  - key: "empire"
    operator: "Equal"
    value: "occupied"
    effect: "NoSchedule"
  - key: "order66"
    operator: "Equal"
    value: "active"
    effect: "NoExecute"
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 2. Vérifier

`kubectl rollout status deployment/millennium-falcon`{{exec}}

`k get pods -l app=millennium-falcon -o wide`{{exec}}

Ses pods peuvent de nouveau se poser sur `controlplane`.

`k get pods -l app=x-wing-squadron -o wide`{{exec}}

`x-wing-squadron`, toujours intact, reste bloqué sur `node01` — il ne tolère ni l'un ni l'autre des deux taints.
