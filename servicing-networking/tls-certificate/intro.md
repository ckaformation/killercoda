# Sécuriser une application avec un certificat TLS

Un namespace applicatif `outer-rim` contient déjà :

- un `ConfigMap` avec la configuration nginx (`default.conf`)
- un `Deployment` `hologram` (image `nginx:alpine`) qui référence un
  `Secret` TLS... qui n'existe pas encore
- un `Service` `hologram` qui expose le tout sur le port `443`

Résultat : le pod ne démarre pas. Tu vas :

1. Générer un certificat auto-signé via `openssl` et créer le `Secret`
   TLS attendu par le déploiement.
2. Restreindre la configuration nginx pour n'accepter que TLS 1.3, et
   vérifier ce comportement avec `curl`.

Le cluster se prépare en arrière-plan pendant que tu lis ces lignes.
