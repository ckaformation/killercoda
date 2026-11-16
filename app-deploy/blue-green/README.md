# Scénario Killercoda — Blue/Green : basculer le trafic entre deux versions

## Contenu

```
blue-green/
├── index.json                   # backend kubernetes-kubeadm-1node, 3 étapes
├── intro.md
├── intro-background.sh          # alias k + wait-for-prep.sh + 2 ConfigMaps + 2 Deployments + Service NodePort + /etc/hosts
├── step1.md / step1-verify.sh   # wait-for-prep.sh ; kubectl patch du selector -> version=green ; curl x6
├── step2.md / step2-verify.sh   # kubectl patch du selector -> version=blue (rollback) ; curl x6
├── step3.md / step3-verify.sh   # kubectl expose deployment lightsaber-green (ClusterIP) ; test depuis un pod busybox temporaire
├── finish.md
└── README.md
```

## Préparation (intro-background.sh)

| Objet | Détail |
|---|---|
| ConfigMap `lightsaber-blue-page` / `lightsaber-green-page` | clé `index.html` : `Sabre laser - version blue` / `... green` |
| Deployment `lightsaber-blue` | 2 réplicas, `nginx:alpine`, labels et selector `app=lightsaber,version=blue`, ConfigMap montée dans `/usr/share/nginx/html`, readinessProbe httpGet `/` |
| Deployment `lightsaber-green` | idem avec `version=green` |
| Service `lightsaber` | `NodePort` 30080, selector `app=lightsaber,version=blue` |
| `/etc/hosts` | `jedi-temple` -> InternalIP du nœud |

La sentinelle `/tmp/.scenario-prep-done` n'est créée qu'une fois que `curl http://jedi-temple:30080` répond `version blue` (120 s maximum dans la préparation, 240 s côté `wait-for-prep.sh`).

## Choix effectués et pourquoi

- **Noms Star Wars** : sabre laser bleu / vert (Luke passe du bleu au vert entre *L'Empire contre-attaque* et *Le Retour du Jedi*), `jedi-temple`, `probe-droid`. Tout dans `default`, comme `rolling-update`, pour éviter les `-n` partout.
- **Page de version via ConfigMap** plutôt qu'une image dédiée : `nginx:alpine` est déjà utilisée dans le cursus, et l'élève peut voir d'où vient la page (`kubectl describe pod`). Le bloc `|` ajoute un retour à la ligne final, pour que la boucle `curl` affiche une réponse par ligne.
- **Selector des Deployments avec les deux labels** (`app` + `version`) : sinon les deux Deployments auraient des selectors qui se chevauchent, et `kubectl expose` (étape 3) recopierait un selector visant aussi blue.
- **Bascule par `kubectl patch`** (une commande cliquable, pas de champ à compléter), avec `kubectl edit` cité comme alternative. Le patch stratégique sur `spec.selector` (une map) ne remplace que la clé `version`.
- **Endpoints via `kubectl get endpointslices -l kubernetes.io/service-name=...`** plutôt que `kubectl get endpoints`, l'API `v1 Endpoints` étant dépréciée depuis la 1.33.
- **NodePort appelé via `jedi-temple`** (IP interne du nœud dans `/etc/hosts`), comme dans `api-gateway`, plutôt que `localhost` (NodePort refusé sur `localhost` dans `kubeadm-from-scratch`).
- **Étape 3 : `kubectl expose`**, réflexe d'examen, qui crée un `ClusterIP` par défaut. Test avec `kubectl run ... --rm -it --restart=Never` (busybox `wget`), autre réflexe d'examen.
- **Vérifications sur le fond** : type et nodePort conservés, selector complet (`app` gardé, `version` changé), les deux Deployments toujours à 2 pods prêts (un rollback blue/green suppose que l'autre version tourne encore), et appels réels (6 `curl` sur le NodePort, `wget` depuis un pod pour le ClusterIP). L'étape 3 vérifie aussi que le trafic public est resté sur blue.
- **`wait-for-prep.sh`** : la préparation inclut le pull de `nginx:alpine` et l'attente de 4 pods prêts, probablement au-delà de 20 s.
- **Version de Kubernetes** : la demande mentionne v1.37. Le scénario n'utilise rien de spécifique à une version et ne la vérifie pas (cf. `CLAUDE.md` : pas de version codée en dur).
- **Pas d'indice ni de solution en menu déroulant** : scénario pédagogique, pas de troubleshooting.

## Sources officielles utilisées

- Services : https://kubernetes.io/docs/concepts/services-networking/service/
- Labels et selectors : https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
- EndpointSlices : https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/
- `kubectl expose` (reprend le selector de la ressource exposée) : https://kubernetes.io/docs/reference/kubectl/generated/kubectl_expose/
- `kubectl patch` : https://kubernetes.io/docs/reference/kubectl/generated/kubectl_patch/
- Doc Killercoda : https://killercoda.com/creators

## Limites connues

**Testé sur le papier uniquement.** Ce qui a été vérifié : syntaxe des scripts (`bash -n`), validité de `index.json`, présence des fichiers référencés, validité YAML des manifestes générés par `intro-background.sh` (via un faux `kubectl`). À vérifier au premier passage :

- **NodePort via `jedi-temple`** : suppose que l'IP interne du nœud répond sur le NodePort, comme dans `api-gateway` et `fundamentals/services`. À contrôler en premier.
- **Durée de la préparation** : non mesurée ; si elle reste sous 20 s, `wait-for-prep.sh` peut être retiré.
- **`wget` dans `nginx:alpine`** (utilisé par `step3-verify.sh` via `kubectl exec deploy/lightsaber-blue`) : supposé fourni par busybox dans l'image Alpine, non exécuté.
- **`kubectl run --rm -it`** : sortie de `wget` puis `pod "probe-droid" deleted` attendues, non observées dans le terminal Killercoda. Accès à Docker Hub supposé pour `busybox:1.36`.
- **Délai de prise en compte du nouveau selector** : quelques secondes au plus attendues ; les messages d'échec des vérifications invitent à relancer.
- **Colonnes affichées** (`SELECTOR` de `get svc -o wide`, `VERSION` de `get pods -L version`, `ENDPOINTS` de `get endpointslices`) : écrites de mémoire, non exécutées.
