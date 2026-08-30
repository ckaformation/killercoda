# Scénario Killercoda — MetalLB : LoadBalancer et HorizontalPodAutoscaler

## Contenu

```
metallb-loadbalancer-hpa/
├── index.json
├── intro.md
├── intro-background.sh     # MetalLB (plage IP dynamique) + metrics-server + app NodePort
├── step1.md / step1-verify.sh   # NodePort -> LoadBalancer, validation curl
├── step2.md / step2-verify.sh   # HorizontalPodAutoscaler
└── finish.md
```

## Choix effectués et pourquoi

- **Plage d'adresses MetalLB calculée dynamiquement**, pas codée en dur
  (contrairement à l'exemple donné, `172.30.1.100-172.30.1.110`) :
  `intro-background.sh` lit l'IP interne réelle du nœud
  (`kubectl get nodes -o jsonpath=...status.addresses...InternalIP`),
  en extrait les 3 premiers octets, et construit la plage
  `<sous-réseau>.100-<sous-réseau>.110`. Ça reproduit exactement le
  format de l'exemple donné, tout en restant valide si ce backend
  Killercoda utilise un sous-réseau différent de celui de l'exemple.

- **MetalLB en mode L2** (pas BGP) : c'est le mode qui ne nécessite
  aucune infrastructure réseau supplémentaire (pas de routeur BGP à
  disposition dans cet environnement), et le plus simple à expliquer
  pour une première prise en main.

- **Manifeste `metallb-native.yaml` v0.16.1**, version affichée sur la
  page d'installation officielle au moment de la rédaction
  (`metallb.universe.tf/installation/`).

- **`metrics-server` installé et patché avec `--kubelet-insecure-tls`**,
  ajouté de moi-même, non demandé explicitement, mais nécessaire : sans
  lui, le HPA de l'étape 2 resterait indéfiniment à `<unknown>/50%`,
  incapable de calculer une utilisation CPU réelle — l'exercice
  demandé ("un HPA qui se déclenchera sur un averageUtilization cpu de
  50") suppose un HPA réellement fonctionnel, pas seulement un objet
  YAML statique. Le flag `--kubelet-insecure-tls` est nécessaire sur un
  cluster kubeadm, dont les certificats de kubelet sont auto-signés
  (metrics-server refuse de leur faire confiance par défaut).

- **`requests.cpu: 100m` sur le Deployment `holonet`**, ajouté de moi-même
  également : un HPA basé sur `averageUtilization` ne peut calculer un
  pourcentage sans demande de ressource de référence — sans elle, le
  HPA échouerait à démarrer (erreur "missing request for cpu").

- **HPA créé via `kubectl autoscale`** (impératif), plutôt qu'un
  manifeste YAML : commande standard et directe pour ce cas d'usage
  simple, cohérente avec l'esprit "pratique rapide" déjà présent dans
  d'autres scénarios du cursus utilisant des commandes impératives.

- **`step2-verify.sh` teste à la fois `spec.metrics[].resource.target.averageUtilization`
  (API `autoscaling/v2`) et `spec.targetCPUUtilizationPercentage`
  (ancienne API `v1`)** : je ne suis pas certain à 100% de la version
  d'API que `kubectl autoscale` produit par défaut sur ce cluster
  (dépend de la version d'API "préférée" négociée avec le serveur) —
  le script accepte les deux structures possibles plutôt que d'échouer
  sur une hypothèse non vérifiée.

- **Réplique de base à 2** (comme demandé, tel que présent dans le
  `Deployment` livré) : je n'ai pas cherché à modifier ce nombre pour
  "mieux coller" à l'exercice HPA — c'est un choix assumé de fidélité à
  la demande, avec la remarque honnête de l'intro sur le lien plutôt
  indirect entre LoadBalancer et HPA.

- **Note de transparence dans `intro.md`** sur le lien HPA/LoadBalancer :
  reprend et reformule directement ton propre questionnement, plutôt
  que d'inventer une justification technique qui n'existe pas
  réellement.

## Sources officielles utilisées

- https://metallb.universe.tf/installation/
- https://metallb.universe.tf/configuration/
- https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- https://github.com/kubernetes-sigs/metrics-server

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- **Le fonctionnement réel de MetalLB en mode L2 dans l'environnement
  virtualisé de Killercoda n'a pas pu être vérifié indépendamment** —
  je m'appuie sur l'exemple de plage IP que tu as toi-même fourni
  (cohérent avec le sous-réseau `172.30.1.x` déjà rencontré dans
  d'autres scénarios multi-nœuds de ce cursus), qui suggère que tu as
  déjà de bonnes raisons de penser que ça fonctionne dans cet
  environnement. C'est le point à surveiller en priorité au premier
  test réel.
- Le calcul dynamique de la plage suppose que l'IP interne du nœud
  reste dans un sous-réseau `/24` cohérent avec un usage MetalLB en L2
  — non vérifié spécifiquement sur ce backend.
- La version `latest` de metrics-server (`.../releases/latest/download/...`)
  n'est pas figée à un numéro précis, contrairement à MetalLB : au cas
  où une future version introduirait un changement incompatible, ce
  serait le premier endroit à vérifier.
