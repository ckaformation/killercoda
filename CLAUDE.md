# CLAUDE.md — Scénarios Killercoda de CKA Formation

Ce repo contient les scénarios Killercoda utilisés par Pierrot (CKA Formation) pour préparer ses élèves aux certifications **CKA** et **CKAD**.

Règle n°1 : **n'invente jamais rien.** Si tu ne sais pas (comportement de Killercoda, d'une version de Kubernetes, d'un backend…), dis-le, et note-le dans la section « Limites connues » du README du scénario.

Références :
- Doc Killercoda : https://killercoda.com/creators
- Exemples officiels : https://github.com/killercoda/scenario-examples (scénarios) et https://github.com/killercoda/scenario-examples-groups (cours / `structure.json`)

---

## 1. Arborescence et `structure.json` (critique)

```
.
├── structure.json            # liste des COURS publiés, dans l'ordre d'affichage
├── <cours>/                  # 1 dossier = 1 cours, référencé dans structure.json
│   ├── <scenario>/           # 1 dossier contenant un index.json = 1 scénario
│   └── <scenario>/
└── Perso/                    # fichiers perso, absent de structure.json → ignoré
```

Règles Killercoda (cf. `scenario-examples-groups`) :
- Dès qu'un `structure.json` existe, **seul son contenu est utilisé** : tout dossier non listé est ignoré.
- Les scénarios placés dans un sous-dossier forment un cours.

Règles du repo :
1. **Exactement deux niveaux : `<cours>/<scenario>/`.** Pas de niveau intermédiaire (`cka/`, `ckad/`…) : la tentative du 13/11/2026 a été annulée (commit « rollback »). La distinction CKA/CKAD se fait dans le titre du cours.
2. **Nouveau scénario dans un cours existant** : il suffit de créer le dossier. Les cours n'ont pas de `structure.json` propre, donc tout sous-dossier contenant un `index.json` apparaît automatiquement. Pas besoin de modifier `structure.json`.
3. **Nouveau cours** : crée le dossier **et** ajoute une entrée dans `structure.json` à la racine, sinon il est ignoré :
   ```json
   {
     "path": "nom-du-dossier",
     "title": "CKA - Titre du cours",
     "description": "Une phrase."
   }
   ```
   Préfixes de titre utilisés : `CKA - `, `CKAD - `, `CKA & CKAD - `.
4. **N'ajoute pas de `structure.json` dans un dossier de cours** sans l'accord de Pierrot : il faudrait alors y lister chaque scénario, sinon ceux qui manquent disparaissent.
5. **Ne renomme et ne déplace aucun dossier existant** sans demander : le `path` sert de référence dans `structure.json`.
6. Noms de dossiers : en anglais, kebab-case, sans accent (ex. `pod-anti-affinity`, `network-policy-troubleshoot`). Le dossier existant `stockage` reste tel quel.
7. Pas de fichier vide de remplissage (`toto.yaml` & co.) : avec git, un dossier est créé avec son premier vrai fichier.
8. Ne touche jamais à `Perso/`.

Avant d'écrire, lis `structure.json` et un scénario existant du même cours pour reprendre son style.

---

## 2. Fichiers d'un scénario

```
<scenario>/
├── index.json
├── intro.md
├── intro-background.sh       # préparation invisible pour l'élève
├── step1.md
├── step1-verify.sh
├── stepN.md / stepN-verify.sh
├── finish.md
└── README.md                 # notes de conception, non référencé dans index.json
```

`intro-foreground.sh` est optionnel (rare). Les scripts sont en mode 644 dans le repo et fonctionnent tels quels.

`index.json` type :

```json
{
  "title": "Taints et Tolerations",
  "description": "Une ou deux phrases : contexte + ce que l'élève va faire.",
  "details": {
    "intro": {
      "text": "intro.md",
      "background": "intro-background.sh"
    },
    "steps": [
      {
        "title": "Taint NoSchedule sur controlplane",
        "text": "step1.md",
        "verify": "step1-verify.sh"
      }
    ],
    "finish": {
      "text": "finish.md"
    }
  },
  "backend": {
    "imageid": "kubernetes-kubeadm-1node"
  }
}
```

Une étape sans vérification n'a simplement pas de clé `verify`.

---

## 3. Environnements (`backend.imageid`)

| imageid | Nœuds | À savoir |
|---|---|---|
| `kubernetes-kubeadm-1node` | `controlplane` | `local-path-provisioner` **non** installé |
| `kubernetes-kubeadm-2nodes` | `controlplane`, `node01` | `local-path-provisioner` et StorageClass `local-path` **déjà installés** (ne pas réinstaller) ; accès à `node01` par `ssh` |
| `ubuntu` | une VM Linux | pas de Kubernetes (ex. `fundamentals/container`) |

- CNI : Cilium (pas besoin d'installer Calico).
- `crictl` peut être absent : installe-le en v1.36.0 si besoin (cf. §4).
- Ne code pas en dur la version de Kubernetes du backend : détecte-la (`kubeadm version -o short`, `kubectl version`).
- Pas de `sudo` : tout s'exécute en root.

---

## 4. `intro-background.sh`

- Commence par `#!/bin/bash` et un bloc de commentaires qui résume la préparation.
- Raccourci `k` :
  ```bash
  ln -sf "$(which kubectl)" /usr/local/bin/k
  ```
  Sur `node01` : `ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes node01 "<commande>"`.
- Attente de l'API avant tout `kubectl` :
  ```bash
  for i in $(seq 1 60); do kubectl get nodes >/dev/null 2>&1 && break; sleep 2; done
  kubectl wait --for=condition=Ready node --all --timeout=120s >/dev/null 2>&1 || true
  ```
- Installation de `crictl` (si nécessaire) :
  ```bash
  if ! command -v crictl >/dev/null 2>&1; then
    CRICTL_VERSION="v1.36.0"
    curl -fsSL "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" -o /tmp/crictl.tar.gz
    tar zxf /tmp/crictl.tar.gz -C /usr/local/bin
    rm -f /tmp/crictl.tar.gz
  fi
  ```
- Les fichiers dont l'élève a besoin (manifests, scripts) sont **écrits depuis `intro-background.sh`** (heredoc). N'utilise pas le mécanisme `assets` de Killercoda, qui s'est montré peu fiable.
- **Préparation longue (plus de 20 secondes)** : dépose `/root/wait-for-prep.sh` dès le début du script. Il attend le fichier sentinelle `/tmp/.scenario-prep-done`, créé à la toute fin. `step1.md` commence alors par `` `/root/wait-for-prep.sh`{{exec}} ``. Modèle : `app-deploy/rolling-update`. En dessous de 20 secondes, pas de `wait-for-prep.sh`.
- Script idempotent (`get || create`) et `|| true` sur ce qui n'est pas critique.

---

## 5. Rédaction des `.md`

- En **français**, en tutoyant l'élève, de façon **concise** et simple.
- `intro.md` : `# Titre`, une phrase d'accroche, puis `## Ce qui est déjà en place` et `## Ce que tu vas faire`.
- `stepN.md` : `# Étape N — <titre>`, sous-parties `## 1. …`, `## 2. …`.
- `finish.md` : `# Bravo !`, un récapitulatif, `## Points clés à retenir`, `## Pour aller plus loin` (liens vers la doc officielle kubernetes.io).
- Commandes cliquables avec `{{exec}}`, **une seule commande par bloc** :
  - commande courte : `` `kubectl get pods -o wide`{{exec}} `` ;
  - commande longue ou multi-ligne : bloc ```` ``` ```` suivi de `{{exec}}`.
- Rends un maximum de commandes exécutables. **Évite les commandes avec des champs à compléter.**
- YAML à ajouter à la main : bloc ```` ```yaml ```` sans `{{exec}}`, en précisant où l'insérer.
- Pour `vi` : « Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`. »
- **Univers Star Wars (films principaux uniquement)** pour les noms de namespaces, deployments, labels, taints, utilisateurs… (ex. `millennium-falcon`, `x-wing-squadron`, `jedi-temple`, `endor`, `order66`). Pas de noms génériques du type `ns-a`, `app1`.

### Scénarios de troubleshooting uniquement (quand Pierrot le précise)

- Énoncé volontairement vague : décris le **symptôme**, jamais la cause, y compris dans les titres d'étapes.
- Indice et solution dans des menus déroulants, avec une ligne vide après `<summary>` :
  ```html
  <details>
  <summary>💡 Indice</summary>

  Texte de l'indice.

  </details>

  <details>
  <summary>✅ Solution</summary>

  Explication + commandes {{exec}}.

  </details>
  ```
- Les autres scénarios n'ont **ni indice ni solution en menu déroulant**.

---

## 6. Scripts `stepN-verify.sh`

- `#!/bin/bash`, `exit 0` en cas de succès, `exit 1` en cas d'échec.
- Message en français qui donne l'attendu et l'obtenu (ex. `"controlplane devrait porter le taint empire=occupied:NoSchedule (obtenu: '$TAINT')."`). `✅` / `❌` acceptés.
- Vérifie le **fond**, pas seulement l'état final : par exemple que le PV a bien été corrigé en `ReadWriteOnce`, et pas seulement que le PVC est `Bound`.
- `kubectl rollout status … --timeout=90s` plutôt qu'une boucle ; `2>/dev/null` sur les `jsonpath` ; jamais de boucle infinie.
- Si un résultat n'est pas strictement déterministe (placement par le scheduler…), invite l'élève à relancer la vérification plutôt que d'échouer sans explication.

---

## 7. `README.md` du scénario

Sections, dans cet ordre :
1. `## Contenu` : arborescence commentée des fichiers.
2. `## Choix effectués et pourquoi`
3. `## Sources officielles utilisées` : liens kubernetes.io / Killercoda.
4. `## Limites connues` : mentionne « testé sur le papier uniquement » tant que Pierrot n'a pas testé, et liste les hypothèses à vérifier au premier passage.

---

## 8. Workflow Git

- **Jamais de push direct sur `main`** : Killercoda se synchronise sur le repo, donc ce qui arrive sur `main` est publié pour les élèves.
- Une branche par scénario ou correction (ex. `job-cronjob`, `fix-coredns-verify`), puis une Pull Request vers `main`. Pierrot teste et merge.
- Messages de commit en français, courts, préfixés par le scénario : `cluster-upgrade : passage de 1.35→1.36 à 1.36→1.37`.
- **Claude ne doit pas apparaître dans les contributeurs** :
  - commite sous l'identité de Pierrot : `git -c user.name=ckaformation -c user.email=ckaformationpro@gmail.com commit …` (l'identité git par défaut des sessions Claude est `Claude <noreply@anthropic.com>`) ;
  - n'ajoute **aucune** ligne `Co-Authored-By` dans les messages de commit.
- Pour une correction, ne modifie que les fichiers concernés.
- Avant de commit, depuis la racine du repo :
  ```bash
  python3 -m json.tool structure.json >/dev/null && echo "structure.json OK"
  for f in */*/index.json; do python3 -m json.tool "$f" >/dev/null || echo "JSON invalide : $f"; done
  for f in */*/*.sh; do bash -n "$f" || echo "Syntaxe bash invalide : $f"; done
  ```
  Vérifie aussi que chaque fichier référencé dans `index.json` existe bien.
