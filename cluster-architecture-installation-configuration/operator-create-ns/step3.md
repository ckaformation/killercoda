# Étape 3 — Déployer la ressource personnalisée

## 1. Écrire la ressource

Une instance de `NamespaceSet`, demandant la création de 3 namespaces. Comme la CRD est `scope: Cluster`, cette ressource n'appartient elle-même à aucun namespace :

`vi /root/namespaceset-cr.yaml`{{exec}}

Contenu à saisir :

```yaml
apiVersion: training.example.com/v1
kind: NamespaceSet
metadata:
  name: my-teams
spec:
  namespaces:
    - team-red
    - team-green
    - team-blue
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 2. Déployer

`kubectl apply -f /root/namespaceset-cr.yaml`{{exec}}

`k get namespacesets`{{exec}}

## 3. Observer l'opérateur réagir

L'opérateur interroge l'API toutes les 10 secondes : laisse-lui un peu de temps.

`watch kubectl get namespaces`{{exec}}

Attends l'apparition de `team-red`, `team-green` et `team-blue`, puis quitte avec `Ctrl+C`.

`k logs -n operators namespace-operator-0 --tail=10`{{exec}}

Tu devrais voir les trois messages de création.
