# Étape 2 — Provisionner et écrire des données

## 1. Crée le PVC

Dans le namespace `storage`, crée un `PersistentVolumeClaim` :

- taille : `1Gi`
- accessMode : `ReadWriteOnce`
- `storageClassName: retain-storage`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
  namespace: storage
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: retain-storage
  resources:
    requests:
      storage: 1Gi
```

```
kubectl get pvc -n storage
```{{exec}}

Avec `volumeBindingMode: WaitForFirstConsumer`, le PVC reste en
`Pending` : le volume n'est provisionné qu'au moment où un pod qui
l'utilise est réellement planifié.

## 2. Crée le pod

Crée un pod dans `storage` qui monte ce PVC sur `/data` :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: data-pod
  namespace: storage
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-pvc
```

```
kubectl get pvc -n storage
kubectl get pod -n storage
```{{exec}}

Le PVC doit maintenant passer à `Bound`.

## 3. Écris un fichier dans le volume

```
kubectl exec -n storage data-pod -- sh -c "echo 'hello depuis le pod' > /data/test.txt"
```{{exec}}

## 4. Vérifie sur le disque du nœud

```
find /opt/local-path-provisioner -name test.txt
```{{exec}}

Le fichier doit apparaître, dans un répertoire créé par le
provisioner pour ce volume.
