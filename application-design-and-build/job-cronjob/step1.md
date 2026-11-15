# Étape 1 — Créer un Job qui se termine 3 fois

## 1. Attendre l'application

`k rollout status deploy holonet -n tatooine`{{exec}}

Si la commande répond `not found`, la préparation n'est pas terminée : attends quelques secondes et relance-la.

## 2. Observer l'existant

`k get deploy,svc,pods -n tatooine`{{exec}}

Le ConfigMap monté dans le pod contient la page servie par le Service :

`k get configmap holonet-index -n tatooine -o yaml`{{exec}}

Depuis un pod, un Service se joint par `<service>.<namespace>` : ici `holonet.tatooine`.

## 3. Générer le manifeste du Job

```
k create job holonet-ping --image=curlimages/curl --dry-run=client -o yaml -- curl holonet.tatooine > job.yaml
```{{exec}}

Ce qui suit `--` est la commande exécutée par le container.

## 4. Ajouter `completions`

Un Job est terminé quand `completions` pods ont réussi (1 par défaut). `k create job` n'a pas d'option pour ce champ : ajoute-le à la main.

`vi job.yaml`{{exec}}

Insère `completions: 3` sous `spec:`, juste avant `template:` :

```yaml
spec:
  completions: 3   # à ajouter
  template:
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 5. Créer le Job et suivre son exécution

`k apply -f job.yaml -n tatooine`{{exec}}

`k wait --for=condition=complete job/holonet-ping -n tatooine --timeout=180s`{{exec}}

`k get job,pods -n tatooine`{{exec}}

Le Job affiche `COMPLETIONS 3/3` et trois pods `holonet-ping-…` sont en `Completed` : ils ont lancé le `curl` l'un après l'autre (`parallelism` vaut 1 par défaut) puis se sont arrêtés, sans être supprimés.

`k logs job/holonet-ping -n tatooine`{{exec}}

Tu y lis la page du ConfigMap : le Job a bien joint le Service.
