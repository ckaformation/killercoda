# Étape 2 — Cloner le ServiceAccount leon en leon-2

## Objectif

Créer un nouveau ServiceAccount, **leon-2**, basé sur **leon**, avec une différence : `automountServiceAccountToken: false` (le token du ServiceAccount ne doit pas être monté automatiquement dans les pods qui l'utiliseraient).

## 1. Exporter leon en YAML

`kubectl get serviceaccount leon -n ops -o yaml > sa.yaml`{{exec}}

## 2. Éditer le fichier avec vi

`vi sa.yaml`{{exec}}

Apporte les modifications suivantes :

- sous `metadata:`, change `name: leon` en `name: leon-2` ;
- supprime les champs générés par le serveur, qui n'ont pas de sens pour un nouvel objet : `resourceVersion`, `uid`, `creationTimestamp` ;
- ajoute, **au même niveau que `metadata:`** (donc pas à l'intérieur de `metadata:`), la ligne :
  ```
  automountServiceAccountToken: false
  ```

Le fichier final doit ressembler à ceci :

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: leon-2
  namespace: ops
automountServiceAccountToken: false
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 3. Appliquer le fichier

`kubectl apply -f sa.yaml`{{exec}}

## 4. Vérifier

`k get sa leon-2 -n ops -o yaml`{{exec}}

Le champ `automountServiceAccountToken: false` doit apparaître dans le résultat.
