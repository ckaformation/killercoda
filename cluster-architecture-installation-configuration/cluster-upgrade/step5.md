# Étape 5 — Upgrader kubelet et kubectl sur le worker

## 1. Vider le nœud (drain)

Le drain d'un nœud se fait toujours **depuis le control-plane**. Bascule sur l'onglet **`controlplane`** :

`kubectl drain node01 --ignore-daemonsets`{{exec}}

## 2. Upgrader kubelet et kubectl sur node01

Rebascule sur l'onglet **`node01`** :

`apt-mark unhold kubelet kubectl`{{exec}}

`apt-get update`{{exec}}

`KUBELET_VERSION=$(apt-cache madison kubelet | awk '{print $3}' | sort -V | tail -1) && apt-get install -y kubelet=$KUBELET_VERSION kubectl=$KUBELET_VERSION`{{exec}}

`apt-mark hold kubelet kubectl`{{exec}}

## 3. Redémarrer kubelet

`systemctl daemon-reload`{{exec}}

`systemctl restart kubelet`{{exec}}

## 4. Remettre le nœud en service (uncordon)

Le uncordon se fait aussi depuis le control-plane. Rebascule sur l'onglet **`controlplane`** :

`kubectl uncordon node01`{{exec}}

## 5. Vérifier l'ensemble du cluster

`kubectl get nodes -o wide`{{exec}}

Les deux nœuds doivent maintenant afficher la version `v1.36.x` et le statut `Ready`.

`kubectl get pods -n kube-system -o wide`{{exec}}

Félicitations : ton cluster kubeadm à deux nœuds est passé de v1.35.x à v1.36.x sans interruption de service.
