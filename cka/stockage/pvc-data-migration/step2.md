# Étape 2 — Copier les données

Crée un `Job` dans `hoth`, avec l'image `bash:5`, qui monte les deux
PVC et copie les données de l'un vers l'autre.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate-data
  namespace: hoth
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: bash:5
        command: ["bash", "-c", "cp -av /old-data/. /new-data/"]
        volumeMounts:
        - name: old-data
          mountPath: /old-data
        - name: new-data
          mountPath: /new-data
      volumes:
      - name: old-data
        persistentVolumeClaim:
          claimName: echo-base-data
      - name: new-data
        persistentVolumeClaim:
          claimName: echo-base-data-retain
```

```
kubectl get jobs -n hoth
```{{exec}}

Vérifie que le Job s'est bien terminé :

```
kubectl get pods -n hoth
```{{exec}}

Vérifie enfin, sur le disque du nœud, que les données sont bien
présentes :

```
find /opt/local-path-provisioner -name rebel-plans.txt
```{{exec}}

Tu dois voir apparaître deux résultats : un dans le répertoire de
l'ancien PVC, un dans celui du nouveau.
