# Étape 2 — Créer la CRD et une ressource personnalisée

## 1. Écrire la CRD

Une CRD (`CustomResourceDefinition`) enseigne à l'API Kubernetes un nouveau type de ressource — ici, `Greeting`, dans un groupe d'API dédié (`training.example.com`), avec un seul champ : `message`.

`vi /root/greeting-crd.yaml`{{exec}}

Contenu à saisir :

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: greetings.training.example.com
spec:
  group: training.example.com
  scope: Namespaced
  names:
    plural: greetings
    singular: greeting
    kind: Greeting
    listKind: GreetingList
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
                message:
                  type: string
              required:
                - message
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

> `scope: Namespaced` : les futures ressources `Greeting` existeront dans un namespace précis (comme un Pod), pas au niveau du cluster entier (comme un Node).

## 2. Appliquer la CRD

`kubectl apply -f /root/greeting-crd.yaml`{{exec}}

`kubectl get crd greetings.training.example.com`{{exec}}

## 3. Créer une ressource Greeting

On crée une instance de ce nouveau type, dans le namespace `luke` :

`vi /root/greeting-luke.yaml`{{exec}}

Contenu à saisir :

```yaml
apiVersion: training.example.com/v1
kind: Greeting
metadata:
  name: bienvenue
  namespace: luke
spec:
  message: "Bienvenue dans le namespace luke"
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

`kubectl apply -f /root/greeting-luke.yaml`{{exec}}

`k get greetings -n luke`{{exec}}

## 4. Observer l'opérateur réconcilier

L'opérateur interroge l'API toutes les 10 secondes : laisse-lui un peu de temps.

`watch kubectl get configmap -n luke`{{exec}}

Attends l'apparition de `bienvenue-greeting`, puis quitte avec `Ctrl+C`.

`k get configmap bienvenue-greeting -n luke -o yaml`{{exec}}

Le champ `data.message` doit contenir le texte du `Greeting` créé au point 3 : l'opérateur a bien "interprété" la ressource personnalisée.
