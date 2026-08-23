# Étape 1 — Créer un static pod à partir d'un manifeste

> Toute cette étape se déroule sur l'onglet **`node01`**.

## 1. Trouver le staticPodPath actuel

Le kubelet lit sa configuration dans `/var/lib/kubelet/config.yaml`. Le champ `staticPodPath` y indique le dossier qu'il surveille en permanence : tout fichier `.yaml`/`.json` qui y apparaît (ou en disparaît) devient (ou cesse d'être) un pod, automatiquement.

`grep staticPodPath /var/lib/kubelet/config.yaml`{{exec}}

Tu devrais voir `/etc/kubernetes/manifests` : c'est le dossier par défaut d'un cluster kubeadm.

`ls /etc/kubernetes/manifests`{{exec}}

Sur `node01`, contrairement à `controlplane`, ce dossier est vide (ou presque) : `node01` est un nœud worker, il n'héberge aucun composant du control-plane.

## 2. Écrire le manifeste du static pod

On crée un pod simple, basé sur l'image `nginx` :

`vi /etc/kubernetes/manifests/static-web.yaml`{{exec}}

Contenu à saisir :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-web
  labels:
    role: myrole
spec:
  containers:
    - name: web
      image: nginx
      ports:
        - name: web
          containerPort: 80
          protocol: TCP
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 3. Vérifier côté Kubernetes

Dès que le fichier est détecté, le kubelet démarre le pod et crée un **pod miroir** dans l'API — visible via `kubectl`, mais pas pilotable par lui (le supprimer avec `kubectl delete` ne ferait que le recréer aussitôt, puisque le kubelet continue de lire le manifeste local). Son nom est suffixé par celui du nœud.

Bascule sur l'onglet **`controlplane`** (c'est là que `kubectl` est configuré) :

`k get pods -o wide`{{exec}}

Tu devrais voir `static-web-node01`, à l'état `Running`.

## 4. Vérifier côté runtime de conteneurs avec crictl

`kubectl` ne montre que le pod miroir, une vue **côté API**. `crictl` interroge directement `containerd` : c'est la vue **côté runtime**, indépendante de l'API server — précieuse quand justement l'API server (lui-même un static pod, sur `controlplane` !) ne répond plus.

Rebascule sur l'onglet **`node01`** :

`crictl ps --name web`{{exec}}

Tu devrais voir un conteneur nommé `web`, à l'état `Running`.
