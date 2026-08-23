# Étape 3 — Ajouter leon-2 au RoleBinding existant

## Objectif

Plutôt que de créer un nouveau `RoleBinding` pour `leon-2`, on va l'ajouter comme second sujet du `RoleBinding` existant (`leon-ops-pod-cleaner`, créé à l'étape 1), qui lie déjà `leon` au `Role` `ops-pod-cleaner`.

## 1. Éditer le RoleBinding

`kubectl edit rolebinding leon-ops-pod-cleaner -n ops`{{exec}}

Dans la section `subjects:`, ajoute une nouvelle entrée pour `leon-2`, sur le même modèle que celle de `leon` :

```yaml
subjects:
- kind: ServiceAccount
  name: leon
  namespace: ops
- kind: ServiceAccount
  name: leon-2
  namespace: ops
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 2. Vérifier

`k auth can-i delete pods --as=system:serviceaccount:ops:leon-2 -n ops`{{exec}}

Doit répondre `yes` : `leon-2` hérite maintenant des mêmes droits que `leon`, via ce `RoleBinding` partagé.
