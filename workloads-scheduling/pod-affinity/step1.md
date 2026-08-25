# Étape 1 — Ajouter une pod affinity à luke

## 1. Observer l'état actuel

`k get pods -o wide`{{exec}}

`yoda` est sur `node01`. `luke` est là où le scheduler a bien voulu le placer, sans contrainte particulière.

## 2. Tenter un edit direct

`kubectl edit pod luke`{{exec}}

Ajoute, dans `spec` (au même niveau que `containers`) :

```yaml
affinity:
  podAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app: yoda
        topologyKey: "kubernetes.io/hostname"
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

Tu devrais obtenir une erreur : l'API server refuse la modification, avec un message du type `Forbidden: pod updates may not change fields other than ...`. Quitte sans réessayer (`Échap` puis `:q!` puis `Entrée` si l'éditeur se rouvre).

## 3. Comprendre pourquoi

Un `Pod` déjà créé est **largement immuable** : en dehors de quelques champs précis (l'image d'un conteneur, les tolerations en ajout, et quelques autres), sa spec ne peut plus être modifiée après coup — y compris `spec.affinity`. C'est une des raisons d'être des contrôleurs comme `Deployment` ou `StatefulSet` : eux gèrent ce cycle "supprimer l'ancien pod, en recréer un nouveau avec la spec à jour" à ta place. Ici, avec un pod nu, c'est à toi de le faire.

## 4. Éditer le fichier, pas l'objet vivant

`vi /root/luke.yaml`{{exec}}

Ajoute le même bloc `affinity` que ci-dessus, dans `spec`, au même niveau que `containers` :

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

## 5. Supprimer et recréer luke

`kubectl delete pod luke`{{exec}}

`kubectl apply -f /root/luke.yaml`{{exec}}

## 6. Vérifier

`k get pods -o wide`{{exec}}

`luke` doit maintenant être sur le même nœud que `yoda` (`node01`) : son affinité l'y contraint, puisque c'est le seul nœud portant un pod avec le label `app=yoda`.
