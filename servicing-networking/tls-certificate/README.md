# Scénario Killercoda — Certificat TLS & Secret Kubernetes

## Contenu

```
tls-secret-certificate/
├── index.json
├── intro.md
├── intro-background.sh   # namespace + configmap + deploy (secret manquant) + service
├── step1.md / step1-verify.sh   # openssl + secret tls + relance du pod
└── step2.md / step2-verify.sh   # restriction TLS 1.3 + vérification curl
└── finish.md
```

## Ressources créées par `intro-background.sh` (namespace `outer-rim`)

- `ConfigMap/hologram-nginx-conf` : clé `default.conf`, config nginx
  SSL avec `ssl_protocols TLSv1.2 TLSv1.3;`.
- `Deployment/hologram` : `nginx:alpine`, monte le ConfigMap sur
  `/etc/nginx/conf.d/default.conf` (subPath) et un volume Secret
  `hologram-tls` sur `/etc/nginx/certs` — secret qui n'existe pas
  encore, le pod reste donc bloqué en `ContainerCreating`.
- `Service/hologram` : `ClusterIP`, port `443`.

## Choix effectués et pourquoi

- **CN attendu : `hologram.local`** (`<nom du service>.local`), cohérent
  avec `server_name hologram.local;` dans la config nginx.
- **Nom du secret imposé : `hologram-tls`**, car c'est ce nom que
  référence le volume du `Deployment` (`secretName: hologram-tls`).
- **Suppression manuelle du pod à l'étape 1** : un pod bloqué en
  attente d'un volume `Secret` manquant reprend sa procédure de
  montage automatiquement une fois le Secret créé, via les tentatives
  périodiques du kubelet, mais ce délai est variable et peut être
  long. Comme pour les scénarios précédents, un redémarrage manuel est
  plus fiable et rapide pour l'expérience élève.
- **`--tls-max 1.2` ajouté au test d'échec de l'étape 2** : point
  technique vérifié sur la documentation officielle curl. `--tlsv1.2`
  seul définit uniquement un **minimum** ("TLS 1.2 ou plus récent"),
  pas une version figée — sans `--tls-max 1.2`, curl négocierait très
  bien du TLS 1.3 contre notre serveur restreint à 1.3, et le test
  "doit échouer" réussirait à tort. `--tlsv1.3` seul reste correct
  pour le test de succès, puisque TLS 1.3 est de toute façon la
  version la plus haute couramment supportée.
- **`curl --resolve hologram.local:443:$CLUSTER_IP --cacert tls.crt`**
  plutôt que `-k`/`--insecure` : permet de garder une validation
  complète (nom d'hôte + confiance du certificat auto-signé comme sa
  propre CA), plus rigoureux pédagogiquement, sans avoir à modifier
  `/etc/hosts`.
- **Extraction du certificat depuis le Secret plutôt que réutilisation
  du fichier local** dans `step2-verify.sh` : plus robuste, ne dépend
  pas de la présence de `tls.crt` au même emplacement que lors de
  l'étape 1.

## Sources utilisées

- Sémantique de `--tlsv1.2` / `--tlsv1.3` / `--tls-max` : documentation
  officielle curl (`docs/cmdline-opts/tlsv1.2.md`,
  `CURLOPT_SSLVERSION`) et confirmation croisée sur `curl.se/bug`.
- Structure standard de l'image Docker officielle `nginx` (fichier
  `nginx.conf` incluant `/etc/nginx/conf.d/*.conf`, image `alpine`
  incluse) : connaissance générale, non re-vérifiée par recherche
  dédiée dans cette conversation.
- Clés fixes `tls.crt` / `tls.key` pour un Secret Kubernetes de type
  `kubernetes.io/tls` : connaissance générale Kubernetes (convention
  documentée et strictement appliquée par `kubectl create secret tls`).

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents.
- **Accès direct à un ClusterIP depuis le nœud** (`kubectl get svc`
  puis `curl` vers le ClusterIP dans `step2.md`/`step2-verify.sh`) :
  fonctionne normalement sur un cluster kubeadm standard (les règles
  kube-proxy s'appliquent au niveau du nœud), mais non re-testé
  spécifiquement sur le backend `kubernetes-kubeadm-1node` de
  Killercoda — à surveiller en priorité, comme les soucis déjà
  rencontrés avec les NodePort sur d'autres scénarios de ce cursus.
- **Délai de reprise du montage de volume Secret** une fois celui-ci
  créé (avant suppression manuelle du pod) : comportement général
  attendu du kubelet, non chronométré précisément.
- Message d'erreur curl exact en cas d'échec TLS 1.2/1.3
  (`SSL_ERROR_SYSCALL`, `alert protocol version`...) peut varier selon
  la bibliothèque TLS liée à `curl` sur l'image Killercoda
  (OpenSSL/GnuTLS/LibreSSL) — `step2.md` reste volontairement vague
  là-dessus plutôt que d'annoncer un message précis non garanti.
