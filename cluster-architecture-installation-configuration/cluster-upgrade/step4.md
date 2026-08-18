# Étape 4 — Upgrader kubeadm sur le worker (node01)

> Bascule sur l'onglet **`node01`** pour cette étape.

## 1. Changer de dépôt de paquets

Même principe qu'à l'étape 2, cette fois sur `node01` :

`sed -i 's/v1\.35/v1.36/' /etc/apt/sources.list.d/kubernetes.list`{{exec}}

## 2. Upgrader le paquet kubeadm

`apt-mark unhold kubeadm`{{exec}}

`apt-get update`{{exec}}

`KUBEADM_VERSION=$(apt-cache madison kubeadm | awk '{print $3}' | sort -V | tail -1) && apt-get install -y kubeadm=$KUBEADM_VERSION`{{exec}}

`apt-mark hold kubeadm`{{exec}}

`kubeadm version`{{exec}}

## 3. Mettre à jour la configuration locale du kubelet

Sur un nœud worker, on n'utilise pas `kubeadm upgrade apply` (réservé au control-plane) mais `kubeadm upgrade node`, qui met à jour la configuration locale du kubelet :

`kubeadm upgrade node`{{exec}}

> Le paquet `kubelet` lui-même n'est pas encore mis à jour à ce stade — c'est l'objet de l'étape suivante.
