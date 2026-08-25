# Étape 2 — Restreindre le DaemonSet à node01

## 1. Poser un label sur node01

`kubectl label node node01 mission=recon`{{exec}}

## 2. Ajouter le nodeSelector correspondant au DaemonSet

`kubectl edit daemonset probe-droid -n hoth`{{exec}}

Dans `spec.template.spec`, ajoute (au même niveau que `containers`) :

```yaml
nodeSelector:
  mission: recon
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 3. Observer

`k get pods -n hoth -o wide`{{exec}}

Le pod sur `controlplane` doit disparaître de lui-même, sans action supplémentaire : contrairement à un `Deployment`, un `DaemonSet` réévalue en continu quels nœuds sont éligibles, et retire directement les pods des nœuds qui ne le sont plus.

`k get daemonset -n hoth`{{exec}}

`DESIRED` doit maintenant afficher `1`.

## 4. Supprimer le répertoire orphelin sur controlplane

Le pod est parti, mais le répertoire qu'il avait créé sur le disque de `controlplane` n'a pas été nettoyé pour autant — un volume `hostPath` n'est jamais géré ni supprimé automatiquement par Kubernetes :

`ls /var/log/probe-droid`{{exec}}

`rm -rf /var/log/probe-droid`{{exec}}

## 5. Vérifier qu'il ne revient pas

`sleep 10 && ls /var/log/probe-droid 2>&1`{{exec}}

Le répertoire doit rester introuvable : si un pod `probe-droid` tournait encore ici, sa boucle l'aurait déjà recréé (il réécrit son fichier toutes les 5 secondes). Son absence confirme que le DaemonSet n'est plus actif sur `controlplane`.

`k get pods -n hoth -o wide`{{exec}}

Seul `node01` doit encore afficher un pod `probe-droid`.
