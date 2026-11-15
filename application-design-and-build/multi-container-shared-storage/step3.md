# Étape 3 — Monter un PVC existant

Un `emptyDir` disparaît avec le pod. Pour servir des données qui survivent au pod, on monte un **PersistentVolumeClaim**.

## 1. Observer le PVC

`k get pv,pvc`{{exec}}

Le PVC `holocron` est `Bound` au PV `holocron-pv` (100Mi, `RWO`). La page web y est déjà.

## 2. Monter le PVC dans nginx

`vi /root/jedi-archives.yaml`{{exec}}

Complète le `spec` du template avec les deux blocs marqués :

```yaml
    spec:
      terminationGracePeriodSeconds: 1
      volumes:                 # à ajouter (bloc)
      - name: html
        persistentVolumeClaim:
          claimName: holocron
      containers:
      - name: nginx
        image: nginx:alpine
        volumeMounts:          # à ajouter (bloc)
        - name: html
          mountPath: /usr/share/nginx/html
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

Le pod ne référence pas le PV : il demande le **PVC** par son nom (`claimName`), et c'est le PVC qui est lié au PV.

## 3. Appliquer et tester

`k apply -f /root/jedi-archives.yaml`{{exec}}

`k rollout status deploy jedi-archives`{{exec}}

`k get pods -l app=jedi-archives`{{exec}}

S'il reste un pod `Terminating`, attends qu'il disparaisse.

`IP=$(k get pod -l app=jedi-archives -o jsonpath='{.items[0].status.podIP}')`{{exec}}

`curl -s $IP`{{exec}}

Tu lis la page `Archives Jedi` : celle qui est stockée sur le PVC.
