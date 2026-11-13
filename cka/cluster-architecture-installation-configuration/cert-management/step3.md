# Étape 3 — Inspecter le certificat servi en direct

`kubeadm certs check-expiration` lit les certificats **sur le disque**. On va maintenant vérifier celui réellement **servi** par l'API server, en interrogeant directement le service `kubernetes` du namespace `default` — celui par lequel n'importe quel pod du cluster atteint l'API.

## 1. Récupérer l'IP du service

Ce service n'est pas résolvable par DNS depuis le nœud lui-même (seuls les pods, configurés pour utiliser CoreDNS, le peuvent) : on cible directement son ClusterIP.

`k get svc kubernetes -n default`{{exec}}

`CLUSTER_IP=$(kubectl get svc kubernetes -n default -o jsonpath='{.spec.clusterIP}') && echo "$CLUSTER_IP"`{{exec}}

## 2. Interroger l'API server avec curl

`-k` ignore la vérification de la chaîne de confiance (le certificat est signé par la CA interne du cluster, que curl ne connaît pas) ; `-v` affiche le détail de la négociation TLS, y compris le certificat présenté :

`CLUSTER_IP=$(kubectl get svc kubernetes -n default -o jsonpath='{.spec.clusterIP}') && curl -v -k "https://$CLUSTER_IP/version"`{{exec}}

Dans la sortie, cherche les lignes commençant par `*` autour de la négociation TLS : `subject:`, `start date:`, `expire date:`, `issuer:`. C'est le certificat **réellement utilisé** par l'API server à cet instant précis — la meilleure confirmation possible que le renouvellement de l'étape 2 a bien été pris en compte, au-delà de ce qu'affichent les fichiers sur le disque.

> La réponse HTTP elle-même (probablement une erreur 401/403, puisqu'on interroge l'API sans authentification) n'a pas d'importance ici : c'est la poignée de main TLS qu'on vient observer, pas le contenu de la réponse.
