# Étape 2 — Ajouter un nodeSelector aux deux Deployments

## 1. rebel-fleet : n'importe quel nœud "side=dark"

`kubectl edit deployment rebel-fleet`{{exec}}

Dans `spec.template.spec`, ajoute un `nodeSelector` (au même niveau que `containers`) :

```yaml
nodeSelector:
  side: dark
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`. Comme `side=dark` est présent sur les deux nœuds, `rebel-fleet` reste libre de se placer sur l'un ou l'autre.

## 2. imperial-garrison : node01 uniquement

`kubectl edit deployment imperial-garrison`{{exec}}

Même principe, mais avec les deux labels cette fois — seul `node01` porte les deux à la fois :

```yaml
nodeSelector:
  side: dark
  order: sith
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 3. Vérifier le placement

`k get pods -l app=rebel-fleet -o wide`{{exec}}

Les 2 pods de `rebel-fleet` peuvent être sur `controlplane`, sur `node01`, ou répartis entre les deux — les deux nœuds sont éligibles.

`k get pods -l app=imperial-garrison -o wide`{{exec}}

Les 2 pods de `imperial-garrison` doivent être **tous les deux** sur `node01` : c'est le seul nœud qui porte à la fois `side=dark` et `order=sith`.
