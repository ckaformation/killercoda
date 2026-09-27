# Scénario Killercoda — Kustomize base/overlays multi-région

## Contenu

```
kustomize-multi-region-scenario/
├── index.json
├── intro.md
├── intro-background.sh   # écrit toute la structure Kustomize sur disque (base + overlay europe-west1 incomplet)
├── step1.md / step1-verify.sh   # compléter + déployer europe-west1
├── step2.md / step2-verify.sh   # dupliquer pour us-west1
└── step3.md / step3-verify.sh   # retirer le Service depuis base + nettoyage manuel
└── finish.md
```

## Choix effectués et pourquoi

- **Application : `busybox:1.36` + applet `httpd`** (`httpd -f -p 8080
  -h /www`), qui sert un fichier généré au démarrage à partir de la
  variable d'env `$REGION` (elle-même issue du `ConfigMap` via
  `configMapKeyRef`) : confirmé comme syntaxe standard busybox
  (`frippery.org/busybox/httpd.html`). Choisi plutôt que
  `hashicorp/http-echo` (utilisé dans un scénario précédent) car ce
  dernier est probablement une image minimale sans shell, ce qui
  aurait empêché d'interpoler dynamiquement la valeur du ConfigMap
  dans son argument `-text`.
- **Patch direct (`patches:` + fichier `configmap-patch.yaml`) plutôt
  que `configMapGenerator`** : un `configMapGenerator` aurait suffixé
  le nom du ConfigMap avec un hash, ce qui n'aurait plus laissé
  exactement 2 fichiers à modifier par overlay comme demandé
  explicitement — le patch direct garde le nom `region-config`
  identique partout, donc rien à ajuster côté `Deployment`.
- **Overlay `europe-west1` livré incomplet** (`REGION: "CHANGE_ME"`)
  plutôt que déjà fonctionnel : l'étape 1 demande explicitement de
  "positionner la région dans l'overlay", ce qui suppose qu'elle n'y
  est pas encore correctement.
- **Les deux namespaces (`europe-west1`, `us-west1`) créés dès le
  départ** par `intro-background.sh` : Kustomize positionne le champ
  `namespace:` sur les ressources mais ne crée jamais l'objet
  `Namespace` lui-même ; sans cette étape, `kubectl apply -k`
  échouerait. Les créer toutes les deux dès le départ évite d'ajouter
  un 3ᵉ fichier par overlay (un `namespace.yaml`), ce qui aurait
  contredit la contrainte "seuls kustomization.yaml et le ConfigMap
  changent" de l'étape 2.
- **`patches:` avec ciblage implicite** (le patch se targete lui-même
  via son propre `apiVersion`/`kind`/`metadata.name`, sans bloc
  `target:` explicite) : syntaxe Kustomize moderne, supportée par la
  version embarquée dans un `kubectl` récent (cohérent avec la
  version 1.35.1 déjà notée pour ce cluster).
- **Étape 3 : clarification apportée sur le "soit...soit..."** de la
  consigne d'origine — retirer uniquement le fichier `service.yaml`
  sans retirer la ligne correspondante de `resources:` ferait échouer
  `kubectl apply -k` (fichier introuvable). `step3.md` demande donc
  de retirer la ligne dans `kustomization.yaml` dans tous les cas, et
  propose la suppression du fichier comme geste additionnel optionnel
  (propreté), pas comme alternative isolée.
- **Vérification de `europe-west1` en plus de `us-west1`** dans
  `step2-verify.sh` : confirme que dupliquer l'overlay n'a pas cassé
  le premier environnement, point pédagogique implicite de l'étape.

## Sources utilisées

- Syntaxe et options de l'applet `httpd` de BusyBox (`-f`, `-p`,
  `-h`) : `frippery.org/busybox/httpd.html`, `busybox.net`.
- Comportement de `configMapGenerator` (suffixe de hash + mise à jour
  automatique des références) et de `patches:` avec ciblage
  implicite : connaissance générale Kustomize, non re-vérifiée par
  recherche dédiée dans cette conversation pour cette partie précise.
- Limite de `kubectl apply` (ne supprime jamais une ressource retirée
  du manifest sans `--prune`) : connaissance générale Kubernetes.

## Limites connues / hypothèses non vérifiées en conditions réelles

- **La structure Kustomize elle-même (patch, duplication, retrait de
  ressource) a été testée réellement** avec le binaire `kustomize
  v5.4.3` (`kustomize build` sur les 3 étapes simulées) : le patch
  direct fonctionne, la duplication pour `us-west1` fonctionne, et le
  retrait de `service.yaml` dans `base` fait bien disparaître le
  `Service` du rendu final, sans toucher au `Deployment`/`ConfigMap`.
  Cette partie n'est donc plus une simple hypothèse.
- **Le reste (déploiement réel sur le cluster, comportement de
  `busybox httpd`, `kubectl apply -k`, accès ClusterIP) n'est testé
  que "sur le papier"**, comme les scénarios précédents — seul le
  rendu YAML généré par Kustomize a pu être vérifié dans cet
  environnement, pas son exécution sur un vrai cluster Kubernetes.
- **L'image officielle `busybox:1.36` inclut bien l'applet `httpd`
  compilée** : très probable (build standard Docker Hub), mais non
  testée directement pour ce tag précis — un ancien retour
  communautaire (2015) mentionne des builds *non officielles* de
  busybox sans `httpd` activé, d'où cette réserve.
- **Accès direct au ClusterIP depuis le nœud** (`curl` dans les 3
  scripts de vérification) : même hypothèse que sur des scénarios de
  stockage précédents (fonctionne normalement sur un kubeadm
  standard), non re-testée spécifiquement ici.
