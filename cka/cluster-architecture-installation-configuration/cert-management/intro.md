# Gestion des certificats Kubernetes avec kubeadm

Bienvenue ! Un cluster kubeadm repose entièrement sur des certificats X.509 : l'API server, `etcd`, le `controller-manager`, le `scheduler`, et le kubeconfig admin en dépendent tous pour s'authentifier mutuellement. Par défaut, ces certificats expirent au bout d'**un an**. Ce scénario couvre le cycle complet : vérifier, renouveler, et confirmer.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud fonctionnel.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Vérifier la date d'expiration des certificats du control-plane.
2. Les renouveler, puis redémarrer le control-plane pour qu'il utilise les nouveaux certificats — **le rechargement à chaud n'est pas supporté**, un redémarrage est obligatoire.
3. Vérifier, en direct, le certificat réellement servi par l'API server, avec `curl -v -k`.

> Pendant l'étape 2, l'API server sera brièvement indisponible (redémarrage du control-plane). Tu retrouveras `crictl`, déjà rencontré dans `static-pods` : c'est justement l'outil qui continue de fonctionner quand `kubectl` ne le peut plus.

C'est parti !
