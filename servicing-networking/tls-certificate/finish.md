# Bravo !

Tu as :

- Généré un certificat auto-signé avec `openssl`, en respectant une
  contrainte de CN.
- Créé un `Secret` Kubernetes de type `kubernetes.io/tls`
  (`tls.crt` / `tls.key`), et compris pourquoi un pod reste bloqué
  tant qu'un volume `Secret` référencé n'existe pas.
- Restreint les versions TLS acceptées par un serveur nginx via
  `ssl_protocols`, et vérifié ce comportement avec `curl` — y compris
  le piège du flag `--tlsv1.2`, qui définit un minimum et non une
  version figée.

## Pour aller plus loin

- Regarde `kubectl describe secret hologram-tls -n outer-rim` :
  Kubernetes ne montre jamais le contenu en clair d'un Secret.
- Teste `curl -v` sur les deux commandes de l'étape 2 pour observer le
  détail de la négociation TLS dans les logs de handshake.
- Explore d'autres directives `ssl_ciphers` ou `ssl_prefer_server_ciphers`
  pour aller plus loin dans le durcissement TLS.
