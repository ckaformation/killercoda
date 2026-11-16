# Scénario Killercoda — Canary : répartir le trafic en jouant sur les réplicas

## Contenu

```
canary/
├── index.json                   # backend kubernetes-kubeadm-1node, 3 étapes
├── intro.md
├── intro-background.sh          # alias k + wait-for-prep.sh + 2 ConfigMaps + /root/x-wing-current.yaml + Deployment x-wing-current (4) + Service NodePort + /etc/hosts
├── step1.md / step1-verify.sh   # wait-for-prep.sh ; cp + sed current->canary + replicas 1 ; scale current à 3 ; apply canary ; ~25 %
├── step2.md / step2-verify.sh   # scale canary à 2 puis current à 2 ; ~50 %
├── step3.md / step3-verify.sh   # scale canary à 4 puis current à 0 ; 100 %
├── finish.md
└── README.md
```

## Préparation (intro-background.sh)

| Objet | Détail |
|---|---|
| ConfigMap `x-wing-current-page` | `index.html` : `version : Current` |
| ConfigMap `x-wing-canary-page` | `index.html` : `version : Canary` |
| `/root/x-wing-current.yaml` | manifeste du Deployment `x-wing-current`, laissé à l'élève pour créer la canary |
| Deployment `x-wing-current` | 4 réplicas, `nginx:alpine`, labels et selector `app=x-wing,track=current`, ConfigMap montée dans `/usr/share/nginx/html`, readinessProbe httpGet `/` |
| Service `x-wing` | `NodePort` 30080, selector `app=x-wing` seul |
| `/etc/hosts` | `yavin` -> InternalIP du nœud |

La sentinelle `/tmp/.scenario-prep-done` n'est créée qu'une fois que `curl http://yavin:30080` répond `version : Current` (120 s maximum dans la préparation, 240 s côté `wait-for-prep.sh`).

## Choix effectués et pourquoi

- **Labels `app` + `track`**, comme le tutoriel officiel (`track: stable` / `track: canary`, 3 réplicas stables + 1 canary). Le Service ne vise que `app`, chaque Deployment a `track` dans son selector pour ne pas se chevaucher avec l'autre.
- **Noms** : `x-wing-current` (le nom contient `-current`, comme demandé) et `x-wing-canary` ; `yavin` pour le nom d'hôte. Tout dans `default`.
- **Création de la canary par copie du manifeste** puis `sed` : le mot `current` n'apparaît que 5 fois dans `/root/x-wing-current.yaml` (nom, 3 labels `track`, ConfigMap), donc `sed -i 's/current/canary/g'` produit exactement la canary, et un second `sed` passe `replicas` à 1. Commandes cliquables, sans champ à compléter ; l'équivalent vi (`:%s/current/canary/g`) est cité pour l'examen. `diff` permet de voir les 6 lignes modifiées.
- **Étape 1 dans l'ordre demandé** : `scale` de current à 3, puis `apply` de la canary.
- **Étapes 2 et 3 : canary augmentée avant de réduire current** (avec `rollout status` entre les deux), pour que l'application garde au moins 4 pods prêts. C'est une adaptation de « la même méthode » : on joue toujours sur les réplicas, seul l'ordre diffère de l'étape 1. Facile à inverser si tu préfères le même ordre partout.
- **`x-wing-current` gardé à 0 réplica** à l'étape 3 (pas supprimé) : le retour arrière par `kubectl scale` est montré, en commande non cliquable pour ne pas casser la vérification.
- **Comptage des réponses** avec `for … curl … | sort | uniq -c` sur 100 requêtes : le résultat se lit directement en pourcentage.
- **Vérifications** : Service inchangé (NodePort 30080, selector `app=x-wing` sans `track`), définition de la canary (`track=canary` dans le selector et le template, `app=x-wing` conservé, ConfigMap `x-wing-canary-page`), réplicas demandés **et** prêts pour chaque version, puis 100 vraies requêtes. Tolérances : 10 à 45 canary à l'étape 1, 30 à 70 à l'étape 2, exactement 100 à l'étape 3. En cas d'écart, le message invite à relancer.
- **NodePort appelé via `yavin`** (IP interne du nœud dans `/etc/hosts`), comme `jedi-temple` dans `blue-green` et `imagine.app` dans `api-gateway`. Pour que ce ne soit pas une boîte noire, l'étape 1 fait afficher la ligne avec `grep yavin /etc/hosts`.
- **`wait-for-prep.sh`** : pull de `nginx:alpine` et 4 pods à rendre prêts, probablement au-delà de 20 s.
- **Version de Kubernetes** : la demande mentionne v1.37 en mono-nœud ; rien n'en dépend et elle n'est pas vérifiée (cf. `CLAUDE.md`).
- **Pas d'indice ni de solution en menu déroulant** : scénario pédagogique, pas de troubleshooting.

## Sources officielles utilisées

- Tutoriel canary (labels `track`, 3 + 1 réplicas, Service sur le label commun) : https://kubernetes.io/docs/tutorials/stateless-application/canary-deployment/
- Services : https://kubernetes.io/docs/concepts/services-networking/service/
- Deployments : https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- `kubectl scale` : https://kubernetes.io/docs/reference/kubectl/generated/kubectl_scale/
- Doc Killercoda : https://killercoda.com/creators

## Limites connues

**Testé sur le papier uniquement.** Ce qui a été vérifié : syntaxe des scripts (`bash -n`), validité de `index.json`, présence des fichiers référencés, validité YAML des manifestes générés, résultat des deux `sed` sur `/root/x-wing-current.yaml`, logique des 3 vérifications avec un faux `kubectl` et un faux `curl`. À vérifier au premier passage :

- **Répartition aléatoire par requête** : je suppose que chaque `curl` (nouvelle connexion) est envoyé au hasard vers l'un des pods prêts, que le Service soit géré par kube-proxy ou par Cilium. Non observé sur ce backend. Si la répartition était faussée (affinité, algorithme différent), les vérifications des étapes 1 et 2 échoueraient : c'est le premier point à contrôler.
- **NodePort via `yavin`** : même hypothèse que `blue-green`, pas encore confirmée sur `kubernetes-kubeadm-1node`.
- **Arrêt des pods current à l'étape 3** : je suppose qu'un pod en cours d'arrêt ne reçoit plus de nouvelles requêtes ; sinon quelques réponses `Current` peuvent apparaître pendant quelques secondes (les messages invitent à relancer).
- **Durée de la préparation** : non mesurée ; si elle reste sous 20 s, `wait-for-prep.sh` peut être retiré.
- **Colonnes affichées** (`TRACK` de `get pods -L track`, `SELECTOR` de `get svc -o wide`, `ENDPOINTS` de `get endpointslices`) : écrites de mémoire, non exécutées.
- **URL de `kubectl scale`** : construite sur le même modèle que les pages `kubectl expose` et `kubectl patch` vérifiées, non vérifiée elle-même.
