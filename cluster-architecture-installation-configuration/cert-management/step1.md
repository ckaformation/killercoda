# Étape 1 — Vérifier la date d'expiration des certificats

## 1. Vue d'ensemble avec kubeadm

`kubeadm certs check-expiration`{{exec}}

Deux tableaux s'affichent :

- les certificats "feuille" (`apiserver`, `apiserver-kubelet-client`, `admin.conf`, `controller-manager.conf`, `scheduler.conf`, `etcd-server`, `etcd-peer`, `etcd-healthcheck-client`, `apiserver-etcd-client`, `front-proxy-client`…), valables **1 an** par défaut ;
- les autorités de certification (`ca`, `etcd-ca`, `front-proxy-ca`), valables **10 ans** par défaut.

La colonne `RESIDUAL TIME` donne le temps restant avant expiration.

## 2. Vue détaillée avec openssl

`kubeadm certs check-expiration` est spécifique à kubeadm. La même information reste accessible avec des outils génériques, utilisables sur n'importe quel certificat X.509, kubeadm ou non :

`openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates`{{exec}}

`openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -subject -issuer`{{exec}}

## 3. Localiser tous les certificats

`ls -la /etc/kubernetes/pki`{{exec}}

Tous les certificats et clés privées du control-plane vivent ici, en clair sur le disque du nœud — d'où l'importance de restreindre l'accès à ce répertoire en production.
