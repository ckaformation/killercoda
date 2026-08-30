# Scénario Killercoda — MetalLB : LoadBalancer et HorizontalPodAutoscaler

## Contenu

```
metallb-loadbalancer-hpa/
├── index.json
├── intro.md
├── intro-background.sh     # wait-for-prep.sh + MetalLB (plage IP dynamique) + metrics-server + app dans son ns dédié
├── step1.md / step1-verify.sh   # attente prep + NodePort -> LoadBalancer "propre", validation curl
├── step2.md / step2-verify.sh   # HorizontalPodAutoscaler
└── finish.md
```

## Historique de mise au point — trois itérations sur la préparation MetalLB

Ce scénario a nécessité plusieurs itérations pour fiabiliser le script
`background`, suite à des tests réels successifs. Historique conservé
ici pour éviter de reproduire les mêmes fausses pistes :

1. **Version initiale** : `kubectl wait --for=condition=ready pod
   --selector=app.kubernetes.io/name=metallb` avant de créer
   l'`IPAddressPool`/`L2Advertisement`. **Échec** : le service `holonet`
   restait `Pending`.

2. **Deuxième hypothèse (fausse piste)** : redémarrage forcé du
   `controller`/`speaker` après création de la pool, sur l'hypothèse
   d'un souci de cache interne du controller. **Sans effet.**

3. **Cause réelle identifiée** (grâce à un test manuel de l'utilisateur,
   qui a réussi à créer les CR et à obtenir une IP externe en dehors du
   script) : le `--selector=app.kubernetes.io/name=metallb` n'a jamais
   été vérifié directement contre les pods réels. S'il ne correspond
   pas exactement, `kubectl wait` peut rendre la main immédiatement
   sans avoir réellement attendu — le script fonçait alors créer les CR
   avant que le webhook de validation MetalLB (servi par le pod
   `controller`) ne soit prêt à répondre, faisant échouer silencieusement
   leur création (aucune instance `IPAddressPool`/`L2Advertisement`
   n'existait après coup).

4. **Correctif final, fourni directement par l'utilisateur** : remplacer
   le `wait` par sélecteur de label par une attente sur des objets et
   conditions connus avec certitude — `kubectl wait
   --for=condition=Available deployment/controller`, puis `kubectl
   rollout status daemonset/speaker` — avant de créer les CR. C'est la
   séquence actuellement en place dans `intro-background.sh`. Une
   vérification défensive (affichage d'un message d'erreur explicite si
   la création des CR échoue malgré tout) reste en place, sans coût et
   utile en cas de régression future.

## Choix effectués et pourquoi

- **Plage d'adresses MetalLB calculée dynamiquement**, pas codée en dur
  (contrairement à l'exemple donné, `172.30.1.100-172.30.1.110`) :
  `intro-background.sh` lit l'IP interne réelle du nœud, en extrait les
  3 premiers octets, et construit la plage
  `<sous-réseau>.100-<sous-réseau>.110`.

- **MetalLB en mode L2** (pas BGP) : le mode le plus simple, sans
  infrastructure réseau supplémentaire nécessaire.

- **Manifeste `metallb-native.yaml` v0.16.1**, version affichée sur la
  page d'installation officielle au moment de la rédaction.

- **Application `holonet` dans son propre namespace applicatif**
  (également nommé `holonet`), corrigé suite à un retour explicite :
  la version précédente déployait l'app dans `default`.

- **Correctif de l'étape 1 sur l'édition du service**, fourni
  directement par l'utilisateur après ses propres tests : passer
  `type: NodePort` à `type: LoadBalancer` ne suffit pas seul. Il faut
  aussi supprimer la ligne `nodePort:` héritée de l'ancien type, et
  ajouter `allocateLoadBalancerNodePorts: false` pour empêcher
  Kubernetes d'en réattribuer un par défaut — pour obtenir un service
  `LoadBalancer` "propre", sans NodePort résiduel. `step1-verify.sh`
  vérifie explicitement les trois points (type, absence de `nodePort`,
  `allocateLoadBalancerNodePorts: false`).

- **`metrics-server` installé et patché avec `--kubelet-insecure-tls`** :
  sans lui, le HPA de l'étape 2 resterait indéfiniment à
  `<unknown>/50%`. Le flag est nécessaire sur un cluster kubeadm à
  certificats auto-signés.

- **`requests.cpu: 100m` sur le Deployment `holonet`** : un HPA basé sur
  `averageUtilization` ne peut calculer un pourcentage sans demande de
  ressource de référence.

- **HPA créé via `kubectl autoscale`** (impératif), plutôt qu'un
  manifeste YAML.

- **`step2-verify.sh` teste à la fois `spec.metrics[].resource.target.averageUtilization`
  (API `autoscaling/v2`) et `spec.targetCPUUtilizationPercentage`
  (ancienne API `v1`)**, par prudence sur la version d'API réellement
  produite par `kubectl autoscale`.

- **Réplique de base à 2** (comme demandé) : voir la remarque de
  transparence dans `intro.md` sur le lien plutôt indirect entre
  LoadBalancer et HPA.

- **`/root/wait-for-prep.sh`** (mécanisme déjà utilisé dans
  `2nodes-cluster-creation`, `kubeadm-cluster-upgrade` et
  `netpol-isolation`), ajouté suite à un retour direct après le test
  réussi : la préparation complète (MetalLB, metrics-server,
  application) prend un temps non négligeable, et l'élève n'avait
  auparavant aucun moyen de savoir quand elle était terminée sans
  observer les pods à la main. Le script est déposé tout en tout début
  du script `background` (quasi instantané), et le fichier témoin
  (`/tmp/.scenario-prep-done`) n'est créé qu'à la toute fin, après la
  dernière vérification (`Deployment holonet` disponible). La première
  commande de l'étape 1 invite l'élève à attendre ce signal avant de
  continuer.

## Sources officielles utilisées

- https://metallb.universe.tf/installation/
- https://metallb.universe.tf/configuration/
- https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- https://github.com/kubernetes-sigs/metrics-server
- https://kubernetes.io/docs/concepts/services-networking/service/#load-balancer-nodeport-allocation (allocateLoadBalancerNodePorts)

## Limites connues

- **Pas encore re-testé en conditions réelles après ce troisième
  correctif** (séquence `condition=Available` + `rollout status`,
  namespace applicatif dédié, correctif du service) — c'est le point à
  vérifier en priorité au prochain test.
- Le calcul dynamique de la plage IP suppose que l'IP interne du nœud
  reste dans un sous-réseau `/24` cohérent avec un usage MetalLB en L2
  — non vérifié spécifiquement sur ce backend.
- La version `latest` de metrics-server n'est pas figée à un numéro
  précis, contrairement à MetalLB.
