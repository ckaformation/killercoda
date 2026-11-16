# Étape 3 — Rollback falco

Reviens à la révision 1 de la release `falco` :

```
helm rollback falco 1 -n falco
```{{exec}}

Vérifie que le niveau de log est bien revenu à `warning` :

```
helm get values falco -n falco
```{{exec}}

```
helm history falco -n falco
```{{exec}}
