# Scénario Killercoda — StorageClass et reclaimPolicy (local-path-provisioner)

## Contenu

```
storage-reclaim-policy/
├── index.json
├── intro.md
├── intro-background.sh   # namespace storage + local-path-provisioner officiel + annotation default
├── step1.md / step1-verify.sh   # création StorageClass retain-storage
├── step2.md / step2-verify.sh   # PVC + Pod + écriture fichier + vérif disque
└── step3.md / step3-verify.sh   # suppression PVC + PV toujours présent + fichier toujours présent
└── finish.md
```

## Corrections de typos (silencieuses, valeurs réelles Kubernetes)

- `WaitForFirstCustomer` → `WaitForFirstConsumer` (seule valeur
  valide du champ `volumeBindingMode`, avec `Immediate`).
- `storageclass.kubernetes.io/is-defaukt-class` →
  `storageclass.kubernetes.io/is-default-class` (annotation standard
  pour marquer une StorageClass par défaut).

## Choix effectués et pourquoi

- **Manifeste officiel `rancher/local-path-provisioner` non modifié**
  (`v0.0.37`, dernière version taguée "Stable" au moment de la
  rédaction, vérifiée sur `github.com/rancher/local-path-provisioner`)
  plutôt qu'une `StorageClass` réécrite à la main : le manifeste crée
  déjà, tel quel, exactement la combinaison décrite dans la demande —
  `provisioner: rancher.io/local-path`, `reclaimPolicy: Delete`,
  `volumeBindingMode: WaitForFirstConsumer`, `ConfigMap
  local-path-config` pointant par défaut vers
  `/opt/local-path-provisioner` — donc pas besoin d'inventer une
  définition YAML. Seule l'annotation `is-default-class` est absente
  du manifeste par défaut ; elle est ajoutée après coup via `kubectl
  patch`.
- **Nom de la StorageClass par défaut : `local-path`** (nom du
  manifeste officiel), non précisé dans la demande initiale — choix
  naturel puisque c'est le nom standard utilisé par ce projet dans
  toute sa documentation.
- **`kubectl exec ... sh -c "echo ... > /data/test.txt"`** plutôt
  qu'un accès interactif : plus simple à exécuter en `{{exec}}`
  Killercoda.
- **Recherche dynamique du PVC/PV dans les scripts de vérification**
  (par `storageClassName: retain-storage`) plutôt que des noms figés :
  même logique que les scénarios précédents, l'élève garde la main sur
  les noms de ses propres ressources (PVC, pod). Seul le nom de la
  `StorageClass` (`retain-storage`) est imposé, comme demandé.
- **Vérification du fichier sur disque via `spec.hostPath.path` du PV
  réel**, avec repli sur un `find /opt/local-path-provisioner -name
  test.txt` générique si ce champ est vide ou absent : évite de
  dépendre d'une convention de nommage de répertoire
  (`pvc-<uid>_<namespace>_<pvc>` ou autre) que je n'ai pas pu confirmer
  précisément pour la version `v0.0.37`.
- **Étape 3 — vérification du statut `Released`** : traitée en
  avertissement (`⚠️`) plutôt qu'en échec bloquant. Le comportement
  attendu (transition `Bound` → `Released` dès que le PVC est
  supprimé, pour un PV en `Retain`) est une connaissance générale
  Kubernetes solide, mais je préfère ne pas faire échouer toute
  l'étape sur ce point précis si un timing particulier décalait
  momentanément l'observation — la présence du PV et du fichier reste
  le critère bloquant.

## Sources utilisées

- Contenu exact du manifeste `local-path-storage.yaml` (StorageClass
  `local-path`, ConfigMap `local-path-config`, chemin par défaut
  `/opt/local-path-provisioner`) et version stable `v0.0.37` :
  `github.com/rancher/local-path-provisioner` (dépôt officiel,
  fichiers `deploy/local-path-storage.yaml` et `README.md`).
- Commande de patch pour marquer une StorageClass comme défaut
  (`storageclass.kubernetes.io/is-default-class`) : confirmée par
  plusieurs guides tiers cohérents entre eux et avec la doc Kubernetes
  générale sur le sujet.

## Limites connues / hypothèses non vérifiées en conditions réelles

- **Testé uniquement "sur le papier"**, comme les scénarios
  précédents.
- **Type de volume produit par le manifeste standard (`hostPath` vs
  `local` avec `nodeAffinity`)** : je pars de l'hypothèse `hostPath`
  (comportement historique/traditionnel de l'installation par
  manifeste, par opposition à l'installation Helm qui expose un choix
  `defaultVolumeType: local | hostPath`), mais je n'ai pas de
  confirmation directe et définitive pour la version `v0.0.37`
  précise. Les scripts de vérification prévoient un repli générique
  (`find /opt/local-path-provisioner`) si `spec.hostPath.path` s'avère
  vide — donc pas de blocage total si cette hypothèse est fausse, mais
  à surveiller au premier test réel.
- **Délai de rollout du provisioner** (`kubectl -n local-path-storage
  rollout status deployment/local-path-provisioner`) : timeout de
  120s choisi par défaut, non chronométré précisément sur ce backend.
