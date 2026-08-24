# Étape 2 — Renouveler les certificats et redémarrer le control-plane

## 1. Renouveler

`kubeadm certs renew all`{{exec}}

Cette commande régénère tous les certificats gérés par kubeadm, signés par les mêmes autorités déjà présentes dans `/etc/kubernetes/pki`. Elle ne redémarre **rien** : les composants du control-plane tournent encore avec les anciens certificats chargés en mémoire.

> D'après la documentation officielle : *"After running the command you should restart the control plane Pods. This is required since dynamic certificate reload is currently not supported for all components and certificates."* Sans redémarrage, le renouvellement ne sert donc à rien dans l'immédiat.

## 2. Redémarrer le control-plane

Les composants du control-plane sont des static pods : pour forcer leur redémarrage, on retire temporairement leurs manifestes du dossier surveillé par le kubelet, puis on les y remet.

`mkdir -p /tmp/manifests-backup`{{exec}}

`mv /etc/kubernetes/manifests/*.yaml /tmp/manifests-backup/`{{exec}}

Ici, `kubectl` ne répond plus : l'API server vient de s'arrêter. On patiente quelques secondes, puis on remet les manifestes en place :

`sleep 10 && mv /tmp/manifests-backup/*.yaml /etc/kubernetes/manifests/`{{exec}}

## 3. Suivre le redémarrage avec crictl

Le temps que l'API server redémarre, `crictl` reste la seule fenêtre sur ce qui se passe réellement :

`watch crictl ps`{{exec}}

Attends que les conteneurs `etcd`, `kube-apiserver`, `kube-controller-manager` et `kube-scheduler` apparaissent tous à l'état `Running`, puis quitte avec `Ctrl+C`.

## 4. Vérifier que kubectl répond de nouveau

`k get nodes`{{exec}}

## 5. Confirmer le renouvellement

`kubeadm certs check-expiration`{{exec}}

La colonne `EXPIRES` doit maintenant indiquer une date environ un an dans le futur par rapport à aujourd'hui — pas la même date qu'à l'étape 1.
