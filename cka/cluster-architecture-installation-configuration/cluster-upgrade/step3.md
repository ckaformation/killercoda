# Étape 3 — Upgrader kubelet et kubectl sur le control-plane

> Reste sur l'onglet **`controlplane`**.

## 1. Vider le nœud (drain)

Avant de mettre à niveau `kubelet`, on marque le nœud non-schedulable et on évacue les pods qui peuvent l'être (les DaemonSets, comme Calico ou kube-proxy, sont ignorés — c'est normal et attendu) :

`kubectl drain controlplane --ignore-daemonsets`{{exec}}

## 2. Upgrader kubelet et kubectl

`apt-mark unhold kubelet kubectl`{{exec}}

`apt-get update`{{exec}}

`KUBELET_VERSION=$(apt-cache madison kubelet | awk '{print $3}' | sort -V | tail -1) && apt-get install -y kubelet=$KUBELET_VERSION kubectl=$KUBELET_VERSION`{{exec}}

`apt-mark hold kubelet kubectl`{{exec}}

## 3. Redémarrer kubelet

`systemctl daemon-reload`{{exec}}

`systemctl restart kubelet`{{exec}}

`systemctl status kubelet --no-pager`{{exec}}

## 4. Remettre le nœud en service (uncordon)

`kubectl uncordon controlplane`{{exec}}

## 5. Vérifier

`kubectl get nodes -o wide`{{exec}}

`controlplane` doit maintenant afficher la version `v1.36.x` dans la colonne `VERSION`, et le statut `Ready`.
