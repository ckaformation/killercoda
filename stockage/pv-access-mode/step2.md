# Étape 2 — Déployer PostgreSQL avec stockage persistant

Voici un template de départ. Il ne respecte pas encore la consigne :
à toi de le compléter.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jedi-archives-db
  namespace: jedi-archives
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jedi-archives-db
  template:
    metadata:
      labels:
        app: jedi-archives-db
    spec:
      containers:
      - name: postgres
        image: postgres:<A_COMPLETER>
        env:
        - name: POSTGRES_PASSWORD
          value: "<A_COMPLETER>"
        volumeMounts:
        - name: data
          mountPath: <A_COMPLETER>
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: <A_COMPLETER>
```

Consignes :

- image : `postgres:16-alpine`
- variable d'environnement `POSTGRES_PASSWORD=secret`
- monter le PVC corrigé à l'étape précédente (`holocron-storage`) sur
  `/var/lib/postgresql/data`

Applique le manifeste corrigé, puis vérifie :

```
kubectl get pods -n jedi-archives
kubectl get pvc -n jedi-archives
```{{exec}}
