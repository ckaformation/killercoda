# Scénario Killercoda — Troubleshooting HPA

## Corrections suite à retour de Pierrot

- **Vérification de disponibilité ajoutée en tout début d'étape 1**,
  via un script unique `wait-for-ready.sh` plutôt que des commandes
  `kubectl wait` visibles à l'élève : `intro-background.sh` écrit ce
  script sur disque (`/root/wait-for-ready.sh`), qui se contente
  d'afficher "Préparation en cours..." pendant qu'il vérifie, en
  interne, l'état réel des pods applicatifs et de `metrics-server`.
  Contrairement au pattern sentinel retiré sur un scénario précédent
  (dont la cause exacte du dysfonctionnement restait floue), ce script
  ne dépend d'aucun fichier sentinel écrit par le script
  d'arrière-plan : il interroge directement l'état vivant du cluster
  via `kubectl` à chaque exécution, ce qui devrait le rendre plus
  robuste.

- **`--cpu` plutôt que `--cpu-percent`** dans la commande `kubectl
  autoscale` (`step1.md`) : `--cpu-percent` est déprécié au profit de
  `--cpu` (accepte un pourcentage comme `60%`, ou une quantité absolue
  comme `500m`), confirmé sur un commit récent de la doc officielle
  `kubernetes/website` et le man `kubectl-autoscale` à jour.
  `step1-verify.sh` n'a pas eu besoin de changer : il vérifie l'objet
  HPA résultant (`spec.metrics[]` / `spec.targetCPUUtilizationPercentage`),
  identique quel que soit le flag utilisé à la création.

## Contenu

```
hpa-troubleshoot/
├── index.json
├── intro.md
├── intro-background.sh   # metrics-server + namespace + quota (5 pods) + deployment
├── step1.md / step1-verify.sh   # kubectl autoscale (1 indice + 1 solution)
├── step2.md / step2-verify.sh   # quota bloquant (aucun indice, conforme à la demande)
└── step3.md / step3-verify.sh   # stress --cpu 1 (1 indice + 1 solution)
└── finish.md
```

## Cohérence numérique du scénario (vérifiée par calcul)

- Requests CPU 10m / pod, limits CPU 50m / pod, quota `limits.cpu: 10`
  (10 cœurs) : à 20 pods, la consommation max possible est
  20 × 50m = 1 cœur, très en dessous du quota CPU — **le quota CPU
  n'est donc jamais réellement bloquant** avec ces chiffres. C'est le
  quota `pods: "5"` qui est la véritable cause du blocage à l'étape 2,
  cohérent avec l'énoncé ("malgré le min à 10, il n'y a que 5 pods").
- Sans charge, l'HPA se stabilise naturellement à son **minimum (10)**,
  pas à son maximum (20) : la formule HPA calcule une utilisation
  proche de 0 % au repos, donc un nombre de replicas désiré très bas,
  plafonné par `minReplicas`. C'est pourquoi l'étape 3 a un vrai rôle
  pédagogique : sans charge CPU réelle, le HPA ne dépasse jamais 10.
- Avec 3 pods sur 10 stressés à leur limite (50m chacun) : utilisation
  moyenne ≈ (3×50m) / (10×10m) = 150 % de la cible de requête, très au
  dessus des 60 % ciblés — de quoi déclencher un scale-up net.

## Choix effectués et pourquoi

- **`metrics-server` avec `--kubelet-insecure-tls`** : requis sur les
  clusters kubeadm, le certificat kubelet n'étant pas signé par une CA
  que `metrics-server` reconnaît par défaut (confirmé sur plusieurs
  sources, dont le README officiel `kubernetes-sigs/metrics-server`
  et la doc de troubleshooting kubeadm officielle).
- **Namespace `kessel-run`, déploiement `millennium-falcon`** : thème
  Star Wars — un test de stress s'accorde bien avec la traversée du
  Kessel Run, connue pour pousser les moteurs du Faucon à leurs
  limites.
- **`command: ["sleep", "infinity"]`** sur le conteneur
  `polinux/stress` : évite que le process `stress` (l'ENTRYPOINT par
  défaut de l'image) ne tourne dès le départ ; le pod reste idle, et
  `stress --cpu 1` n'est lancé qu'à l'étape 3 via `kubectl exec`, en
  plus du process principal.
- **Indice + solution ajoutés à l'étape 2** (suite à retour de
  Pierrot) : initialement sans aucun indice, conformément à la
  demande d'origine ; l'indice pointe vers les quotas du namespace
  sans donner le nom exact de la ressource en cause, et la solution
  détaille la commande d'édition du `ResourceQuota`.
- **Quota jamais nommé explicitement dans les textes visibles par
  l'élève** (`intro.md`, `step2.md`) : seul `step2-verify.sh` et
  `intro-background.sh` y font référence.
- **Commandes `kubectl top pod` / `kubectl get hpa -w` laissées sans
  `{{exec}}`** dans la solution de l'étape 3 : elles sont censées
  tourner dans de nouveaux onglets de terminal, en parallèle des
  `stress` déjà lancés — je n'ai pas de confirmation de syntaxe
  Killercoda pour cibler un onglet précis avec `{{exec}}`, donc j'ai
  préféré une instruction en prose ("dans un nouvel onglet...") plutôt
  que de risquer d'exécuter la commande dans le mauvais terminal.
- **Les 3 commandes `kubectl exec ... stress --cpu 1 &`** également
  laissées sans `{{exec}}` : elles contiennent des placeholders
  (`<pod-1>`, etc.) à remplacer par l'élève.
- **`step3-verify.sh` vérifie `currentReplicas > 10`** (au-delà du
  minimum), plutôt qu'un nombre précis : le calcul ci-dessus suggère
  qu'un scale-up déclenché par 3 pods stressés sur 10 peut aller
  au-delà d'un simple "+1" (le comportement de scale-up par défaut de
  Kubernetes autorise un doublement rapide) — je ne voulais donc pas
  imposer un nombre exact de replicas dans la vérification.

## Sources utilisées

- Nécessité de `--kubelet-insecure-tls` sur kubeadm : README officiel
  `kubernetes-sigs.github.io/metrics-server`, doc troubleshooting
  kubeadm de kubernetes.io, et plusieurs guides tiers cohérents entre
  eux.
- Syntaxe `kubectl autoscale` et structure `spec.metrics[]` d'un HPA
  `autoscaling/v2` : connaissance générale Kubernetes, non re-vérifiée
  par recherche dédiée dans cette conversation.
- Comportement par défaut du scale-up/scale-down HPA (fenêtres de
  stabilisation, politiques de pourcentage/pods par intervalle) :
  connaissance générale Kubernetes, non re-vérifiée spécifiquement
  pour cette conversation.

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents.
- **Délai avant que `metrics-server` expose des métriques
  exploitables** : `intro-background.sh` boucle jusqu'à 100s
  (20×5s) sur `kubectl top pod`, marge jugée raisonnable mais non
  chronométrée précisément sur ce backend.
- **Magnitude exacte du scale-up à l'étape 3** : le calcul ci-dessus
  suggère un saut potentiellement important (vers le maximum de 20),
  pas nécessairement un "+1" progressif — `step3-verify.sh` reste
  donc volontairement peu strict (`> 10`) plutôt que d'exiger un
  nombre précis, mais le comportement réel dépendra aussi du délai
  exact entre le lancement du `stress` et la vérification.
- **Comportement de `kubectl exec ... -- stress --cpu 1 &`
  en arrière-plan dans un terminal web Killercoda** : je pars du
  principe que le `&` fonctionne normalement dans ce contexte, non
  re-testé spécifiquement.
