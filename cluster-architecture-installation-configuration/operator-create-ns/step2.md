# Étape 2 — Déployer la CustomResourceDefinition

## 1. Écrire la CRD

`NamespaceSet` : un nouveau type de ressource, dans le groupe d'API `training.example.com`, avec un seul champ, `namespaces` (une liste de noms). Comme elle pilote la création de `Namespace` — des objets eux-mêmes cluster-scoped — on la déclare `scope: Cluster` plutôt que `Namespaced`.

`vi /root/namespaceset-crd.yaml`{{exec}}

Contenu à saisir :

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: namespacesets.training.example.com
spec:
  group: training.example.com
  scope: Cluster
  names:
    plural: namespacesets
    singular: namespaceset
    kind: NamespaceSet
    listKind: NamespaceSetList
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                namespaces:
                  type: array
                  items:
                    type: string
              required:
                - namespaces
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 2. Déployer la CRD

`kubectl apply -f /root/namespaceset-crd.yaml`{{exec}}

## 3. Vérifier

`k get crd namespacesets.training.example.com`{{exec}}

`k api-resources | grep namespaceset`{{exec}}

La ressource `namespacesets` doit maintenant apparaître dans l'API, comme n'importe quel type natif.
