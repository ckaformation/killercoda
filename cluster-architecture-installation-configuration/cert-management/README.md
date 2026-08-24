# Scénario Killercoda — Gestion des certificats Kubernetes avec kubeadm

## Contenu

```
kubeadm-certs-management/
├── index.json
├── intro.md
├── intro-background.sh     # alias k + crictl (installation défensive)
├── step1.md / step1-verify.sh   # kubeadm certs check-expiration + openssl
├── step2.md / step2-verify.sh   # kubeadm certs renew all + redémarrage control-plane
├── step3.md / step3-verify.sh   # curl -v -k contre le ClusterIP du service kubernetes
└── finish.md
```

## Choix effectués et pourquoi

- **Backend : `kubernetes-kubeadm-1node`.** Le sujet (certificats du
  control-plane) ne nécessite pas de second nœud ; contrairement à
  `static-pods`, il n'y a ici aucun risque à isoler sur un worker,
  puisque la manipulation porte justement, et volontairement, sur le
  control-plane lui-même.

- **Redémarrage du control-plane par retrait/remise des manifestes**
  (`mv .../manifests/*.yaml /tmp/... puis retour`), pas
  `systemctl restart kubelet` seul. Plusieurs sources trouvées
  suggèrent qu'un simple redémarrage du service kubelet suffit, mais
  cette affirmation me semble contestable : un kubelet qui redémarre ne
  tue pas nécessairement les conteneurs de static pods déjà en cours
  d'exécution (gérés indépendamment par containerd) — c'est d'ailleurs
  précisément ce que `static-pods` établit dans ce même cursus. La
  méthode retenue ici (retirer le manifeste, ce qui fait activement
  arrêter le pod par le kubelet, puis le remettre) est sans ambiguïté,
  documentée par plusieurs sources indépendantes, et cohérente avec la
  mécanique déjà enseignée.

- **Tous les manifestes déplacés simultanément**, plutôt que un par un
  dans un ordre de dépendance strict (`etcd` puis `apiserver` puis le
  reste). Les deux approches sont attestées par des sources réelles.
  J'ai retenu la version simultanée pour sa simplicité en tant qu'étape
  de scénario ; les composants du control-plane sont conçus pour tolérer
  une indisponibilité transitoire de leurs dépendances (retries internes),
  un comportement déjà requis pour survivre à un redémarrage complet
  d'un nœud.

- **`crictl` pour suivre le redémarrage**, pas `kubectl` : pendant la
  fenêtre où les manifestes sont retirés, l'API server est concrètement
  indisponible, donc `kubectl` ne répond pas. Callback direct et
  volontaire vers `static-pods`, qui établit déjà ce point.

- **`curl -v -k` contre le **ClusterIP** du service `kubernetes`, pas
  contre `kubernetes.default.svc`** (demandé comme "le service kube de
  l'apiserver", mais le nom DNS n'est pas la bonne cible ici) : le nom
  DNS `kubernetes.default.svc.cluster.local` n'est résolvable que
  depuis l'intérieur d'un pod, configuré pour utiliser CoreDNS comme
  résolveur — pas depuis le nœud lui-même, en dehors de tout pod, où
  s'exécute l'élève. Cibler le ClusterIP directement contourne ce
  problème (les ClusterIP sont routées par des règles iptables/IPVS
  présentes sur chaque nœud, indépendamment de toute résolution DNS),
  et reste fidèle à l'intention de la demande. Récupéré dynamiquement
  (`kubectl get svc kubernetes -o jsonpath=...`), jamais supposé fixe
  (`10.96.0.1` est une convention courante, pas une garantie).

- **`/version` comme endpoint ciblé** : accessible sans body complexe,
  suffisant pour observer la poignée de main TLS (l'objectif réel de
  cette étape) sans se soucier du code de retour HTTP exact (401/403
  attendu puisque la requête n'est pas authentifiée — précisé
  explicitement dans `step3.md` pour ne pas dérouter l'élève).

## Sources officielles utilisées

- https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/ (page officielle, citée directement dans `step2.md` : nécessité du redémarrage, rechargement à chaud non supporté)
- https://kubernetes.io/docs/setup/best-practices/certificates/
- https://kubernetes.io/docs/reference/setup-tools/kubeadm/generated/kubeadm_certs/kubeadm_certs_renew_apiserver/

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le redémarrage simultané de tous les composants du control-plane
  (plutôt que séquentiel) n'a pas pu être testé en conditions réelles
  sur ce backend précis — les deux approches sont documentées par des
  sources tierces indépendantes, mais je n'ai pas de confirmation
  directe que l'approche simultanée fonctionne sans accroc sur ce
  backend Killercoda spécifique. À surveiller en priorité au premier
  test réel ; si ça pose problème, repasser à un redémarrage séquentiel
  (`etcd` d'abord) serait le premier correctif à essayer.
- Le seuil de fraîcheur utilisé dans `step2-verify.sh` pour confirmer
  qu'un renouvellement a bien eu lieu (`notBefore` de moins de 15
  minutes) est arbitraire ; à ajuster si le scénario met plus de temps
  que prévu à être testé après la manipulation.
