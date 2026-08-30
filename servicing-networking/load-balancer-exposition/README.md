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

- **`kubectl wait --for=condition=Established` sur les deux CRD, avant
  toute création d'instance** (correctif appliqué après un second test
  réel, qui a permis de confirmer la cause précise). Le premier
  correctif (redémarrage du controller/speaker, conservé ci-dessous)
  partait de l'hypothèse d'un souci de cache côté controller. Le test a
  montré autre chose, plus en amont : aucune instance
  `IPAddressPool`/`L2Advertisement` n'existait du tout après le script
  `background` — signe que le `kubectl apply` de ces objets avait
  échoué silencieusement (le script n'avait pas de vérification
  d'erreur à cet endroit), très probablement avec une erreur du type
  `no matches for kind IPAddressPool`, parce que les CRD correspondantes
  n'étaient pas encore pleinement enregistrées côté API server au
  moment de l'apply — le `kubectl wait` sur les *pods* MetalLB ne
  garantit pas ça. Une vérification défensive a aussi été ajoutée juste
  après la création (`kubectl get ipaddresspool`/`l2advertisement`),
  qui affiche un message d'erreur explicite dans les logs si jamais ça
  échouait de nouveau, pour ne plus jamais reproduire un diagnostic à
  l'aveugle comme celui-ci.

- **Redémarrage forcé du `controller` et du `speaker` MetalLB, juste
  après la création de l'`IPAddressPool`/`L2Advertisement`** (premier
  correctif, conservé par précaution même si l'attente sur
  "Established" ci-dessus semble être la vraie cause) : partait de
  l'hypothèse que le controller pouvait manquer l'événement `WATCH` de
  la pool si son cache interne n'avait pas fini de se synchroniser au
  moment de sa création. Sans effet mesurable constaté lors du second
  test (puisque la pool n'existait de toute façon pas encore à ce
  moment-là) — laissé en place en filet de sécurité supplémentaire,
  sans certitude qu'il soit nécessaire.

## Sources officielles utilisées

- https://metallb.universe.tf/installation/
- https://metallb.universe.tf/configuration/
- https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- https://github.com/kubernetes-sigs/metrics-server

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- **MetalLB a révélé un vrai problème lors de deux tests successifs en
  conditions réelles** : le premier correctif (redémarrage
  controller/speaker) n'a pas suffi ; le second diagnostic (aucune
  instance `IPAddressPool`/`L2Advertisement` créée du tout) a permis
  d'identifier une cause plus fondamentale (CRD pas encore
  `Established` au moment de l'apply), maintenant corrigée via
  `kubectl wait --for=condition=Established`. **Pas encore re-testé en
  conditions réelles après ce second correctif** — c'est le point à
  vérifier en priorité au prochain test.
- Le calcul dynamique de la plage suppose que l'IP interne du nœud
  reste dans un sous-réseau `/24` cohérent avec un usage MetalLB en L2
  — non vérifié spécifiquement sur ce backend.
- La version `latest` de metrics-server (`.../releases/latest/download/...`)
  n'est pas figée à un numéro précis, contrairement à MetalLB : au cas
  où une future version introduirait un changement incompatible, ce
  serait le premier endroit à vérifier.
