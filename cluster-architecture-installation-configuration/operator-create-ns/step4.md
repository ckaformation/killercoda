# Étape 4 — Faire évoluer l'opérateur et son RBAC

## Objectif

On veut que l'opérateur pose aussi un label `managed-by=namespace-operator` sur chaque namespace qu'il gère.

## 1. Modifier le StatefulSet

`kubectl edit statefulset namespace-operator -n operators`{{exec}}

Repère le commentaire `# TODO: ajouter ici la commande pour labelliser le namespace`, et ajoute juste en dessous (même indentation que la ligne `kubectl create namespace "$ns"` juste au-dessus) :

```
kubectl label namespace "$ns" managed-by=namespace-operator --overwrite
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 2. Attendre le redémarrage du pod

Modifier le `StatefulSet` déclenche le remplacement de son pod avec la nouvelle version du script :

`kubectl rollout status statefulset/namespace-operator -n operators`{{exec}}

## 3. Observer l'échec

`watch kubectl get namespace team-red -o jsonpath="{.metadata.labels}"`{{exec}}

Le label n'apparaît pas. Quitte avec `Ctrl+C`, puis regarde les logs :

`k logs -n operators namespace-operator-0 --tail=10`{{exec}}

Tu devrais voir une erreur `Forbidden` : le `ClusterRole` de l'opérateur n'autorise pas le verbe `patch` sur `namespaces` — nécessaire pour `kubectl label` (qui, en coulisses, envoie une requête PATCH à l'API). Confirme-le :

`k auth can-i patch namespaces --as=system:serviceaccount:operators:namespace-operator`{{exec}}

Doit répondre `no`.

## 4. Corriger le ClusterRole

`kubectl edit clusterrole namespace-operator-role`{{exec}}

Dans la règle portant sur `resources: ["namespaces"]`, ajoute `patch` à la liste des `verbs` (à côté de `get`, `list`, `create`).

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 5. Vérifier

`k auth can-i patch namespaces --as=system:serviceaccount:operators:namespace-operator`{{exec}}

Doit maintenant répondre `yes`. Laisse à l'opérateur le temps de son prochain cycle (jusqu'à 10 secondes), puis :

`k get namespace team-red team-green team-blue --show-labels`{{exec}}

Les trois namespaces doivent maintenant afficher le label `managed-by=namespace-operator`.
