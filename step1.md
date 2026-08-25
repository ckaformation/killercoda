# Étape 1 — Ajouter une pod affinity à luke, puis le lancer

## 1. Observer l'état actuel

`k get pods -o wide`{{exec}}

Seul `yoda` existe, sur `node01`.

## 2. Compléter le fichier de luke

`cat /root/luke.yaml`{{exec}}

`vi /root/luke.yaml`{{exec}}

Ajoute, dans `spec` (au même niveau que `containers`), une pod affinity ciblant `yoda` :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: luke
  labels:
    app: luke
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app: yoda
          topologyKey: "kubernetes.io/hostname"
  containers:
    - name: nginx
      image: nginx:alpine
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 3. Lancer luke

`kubectl apply -f /root/luke.yaml`{{exec}}

## 4. Vérifier

`k get pods -o wide`{{exec}}

`luke` doit se placer sur le même nœud que `yoda` (`node01`) : son affinité l'y contraint, puisque c'est le seul nœud portant un pod avec le label `app=yoda`.
