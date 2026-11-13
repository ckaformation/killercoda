# Étape 4 — StatefulSet redis : modifier le CPU request (OnDelete)

## 1. Écrire le StatefulSet

Comme tout `StatefulSet`, il a besoin d'un `Service` headless associé (`clusterIP: None`). Note bien `updateStrategy: OnDelete` : on y revient juste après.

`vi /root/jedi-archive.yaml`{{exec}}

Contenu à saisir :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: jedi-archive
spec:
  clusterIP: None
  selector:
    app: jedi-archive
  ports:
    - port: 6379
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: jedi-archive
spec:
  serviceName: jedi-archive
  replicas: 1
  updateStrategy:
    type: OnDelete
  selector:
    matchLabels:
      app: jedi-archive
  template:
    metadata:
      labels:
        app: jedi-archive
    spec:
      containers:
        - name: redis
          image: redis:7-alpine
          resources:
            requests:
              cpu: "100m"
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 2. Déployer

`kubectl apply -f /root/jedi-archive.yaml`{{exec}}

`k get pods -l app=jedi-archive`{{exec}}

Attends que `jedi-archive-0` soit `Running`.

## 3. Modifier le CPU request

`kubectl edit statefulset jedi-archive`{{exec}}

Dans `resources.requests`, change `cpu: "100m"` en `cpu: "250m"`.

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 4. Constater que rien ne se passe... pour l'instant

`k get pod jedi-archive-0 -o jsonpath='{.spec.containers[0].resources.requests.cpu}'`{{exec}}

Toujours `100m` ! Avec `updateStrategy: OnDelete`, le contrôleur du StatefulSet **ne redémarre jamais les pods de lui-même** quand le template change (contrairement à `RollingUpdate`, la stratégie par défaut). Le nouveau template est enregistré, mais n'est appliqué qu'aux pods créés **après** — donc seulement si tu en supprimes un toi-même.

## 5. Supprimer le pod pour appliquer le changement

`kubectl delete pod jedi-archive-0`{{exec}}

`k get pods -l app=jedi-archive -o wide`{{exec}}

Attends que le nouveau `jedi-archive-0` soit `Running`.

## 6. Vérifier

`k get pod jedi-archive-0 -o jsonpath='{.spec.containers[0].resources.requests.cpu}'`{{exec}}

Doit maintenant afficher `250m`.
