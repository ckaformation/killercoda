# Bravo !

Tu viens de parcourir le cycle complet de gestion des certificats d'un cluster kubeadm :

1. **Vérification** : `kubeadm certs check-expiration` (vue d'ensemble kubeadm) et `openssl x509` (vue générique, applicable à n'importe quel certificat X.509).
2. **Renouvellement** : `kubeadm certs renew all`, puis redémarrage du control-plane en retirant/remettant les manifestes des static pods — étape obligatoire, le rechargement à chaud n'étant pas supporté.
3. **Vérification en direct** : `curl -v -k` contre le ClusterIP du service `kubernetes`, pour inspecter le certificat réellement servi, pas seulement celui présent sur le disque.

## Points clés à retenir

- Les certificats générés par kubeadm expirent après **1 an** (certificats "feuille") ou **10 ans** (autorités de certification) par défaut.
- `kubeadm certs renew` ne redémarre rien : sans redémarrage du control-plane, les composants continuent d'utiliser les anciens certificats déjà chargés en mémoire, jusqu'au prochain redémarrage (planifié ou non).
- Retirer puis remettre un manifeste de static pod dans le dossier surveillé par le kubelet force son redémarrage — la même mécanique que dans `static-pods`, appliquée ici à un cas d'usage réel.
- `crictl` reste utilisable même quand l'API server est indisponible (y compris quand c'est l'API server lui-même qu'on redémarre) : un réflexe de diagnostic à garder pour ce genre de situation.
- Le service `kubernetes.default.svc` n'est résolvable par DNS que depuis l'intérieur d'un pod (via CoreDNS) — pas depuis le nœud lui-même, où il faut cibler le ClusterIP directement.
- Vérifier un certificat "sur le disque" (fichier `.crt`) et vérifier le certificat "en vol" (réellement présenté lors d'une connexion TLS) sont deux vérifications différentes, complémentaires — la seconde est la seule à confirmer qu'un composant a effectivement rechargé son nouveau certificat.

## Pour aller plus loin

- Certificate Management with kubeadm : https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/
- PKI certificates and requirements : https://kubernetes.io/docs/setup/best-practices/certificates/
