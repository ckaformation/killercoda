# Scénario Killercoda — nodeSelector et scheduling

## Contenu

```
node-selector-scheduling/
├── index.json
├── intro.md
├── intro-background.sh     # labels side=dark, taint retiré, 2 deployments sans nodeSelector
├── step1.md / step1-verify.sh   # label order=sith sur node01
├── step2.md / step2-verify.sh   # nodeSelector sur les 2 deployments
├── step3.md / step3-verify.sh   # retrait du label + rollout restart
├── step4.md / step4-verify.sh   # arrêt du kube-scheduler + pod avec nodeName
└── finish.md
```

## Choix effectués et pourquoi

- **Découpage en 4 étapes Killercoda**, contre 3 phases dans la demande
  initiale : "ajouter le label" et "configurer les nodeSelector des deux
  Deployments" sont deux tâches distinctes avec des critères de
  vérification propres — les séparer donne un point de contrôle
  intermédiaire, cohérent avec la granularité déjà adoptée dans
  `workload-scheduling-basics` et `init-container-secrets-configmap`.

- **Retrait explicite du taint control-plane dans
  `intro-background.sh`**, même si ce scénario utilise le backend
  `kubernetes-kubeadm-2nodes` "tel quel" (sans reset, comme
  `static-pods` ou `kubeadm-certs-management`). Je n'ai pas de
  confirmation certaine que ce taint soit déjà absent nativement sur ce
  backend — et tout le scénario repose justement sur la possibilité de
  scheduler sur `controlplane` selon les labels, pas sur un taint. Le
  retirer moi-même élimine cette incertitude au lieu de la laisser
  peser sur le bon déroulement de l'exercice.

- **Deux Deployments livrés sans `nodeSelector`** (`rebel-fleet`,
  `imperial-garrison`), à 2 réplicas chacun, demandé explicitement :
  c'est à l'élève de l'ajouter aux étapes 1 et 2, pas quelque chose de
  pré-configuré.

- **Vérification du placement de `rebel-fleet` par label du nœud, pas
  par répartition exacte 1/1.** Rien ne garantit que le scheduler
  répartisse exactement un pod par nœud entre deux nœuds également
  éligibles (pas d'anti-affinité stricte par défaut entre pods d'un
  même ReplicaSet) — `step2-verify.sh` vérifie donc que chaque pod de
  `rebel-fleet` est bien sur un nœud portant `side=dark`, quel que soit
  le nombre exact de pods sur chaque nœud.

- **`kubectl label node controlplane side-`** (syntaxe avec tiret final)
  pour le retrait du label à l'étape 3 : syntaxe standard `kubectl
  label`, la plus directe pour ce cas.

- **`kube-scheduler` plutôt qu'un autre composant du control-plane**
  pour l'étape 4 (demandé explicitement) : c'est aussi, à dessein, le
  choix le plus sûr parmi les static pods du control-plane à
  manipuler — contrairement à `kube-apiserver` ou `etcd`
  (`kubeadm-certs-management`), l'arrêter n'interrompt ni `kubectl`, ni
  les pods déjà en cours d'exécution. Mentionné explicitement dans
  `step4.md` pour que l'élève comprenne pourquoi cette manipulation est
  moins risquée que celles vues dans `kubeadm-certs-management`.

- **Pas de restauration automatique du kube-scheduler en fin de
  scénario** : non demandé explicitement, et forcer une étape de
  restauration aurait ajouté de la charge sans objectif pédagogique
  nouveau. Une note dans `step4.md` suggère la commande de
  restauration, sans en faire une étape vérifiée.

- **Noms à thème Star Wars** (`rebel-fleet` : mobile, peut se poser
  n'importe où ; `imperial-garrison` : base fixe, cohérent avec sa
  contrainte stricte à `node01` ; `vader` pour le pod isolé de l'étape
  4 ; labels `side=dark`/`order=sith`), conformément à la préférence
  indiquée pour ce cursus.

## Sources officielles utilisées

- https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/
- https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#restarting-a-deployment

## Limites connues

- Testé uniquement "sur le papier" : pas d'accès direct à Killercoda.
- Le retrait du taint control-plane dans `intro-background.sh` utilise
  `2>/dev/null || true`, donc reste silencieux que le taint ait existé
  ou non — cohérent avec le comportement déjà utilisé dans
  `2nodes-cluster-creation`, mais je n'ai pas de confirmation directe
  du taint réellement présent (ou non) nativement sur ce backend.
