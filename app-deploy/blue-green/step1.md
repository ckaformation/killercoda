# Étape 1 — Basculer le trafic sur green

La version green est déployée et prête, mais le Service `lightsaber` envoie encore tout le trafic vers blue. Tu vas basculer le trafic sur green.

## 0. Attendre que l'environnement soit prêt

`/root/wait-for-prep.sh`{{exec}}

Attends qu'elle affiche « C'est pret ! » avant de continuer.

## 1. Observer l'état actuel

`kubectl get deployments --show-labels`{{exec}}

Les deux versions tournent, chacune avec 2 pods prêts.

`kubectl get pods -L version -o wide`{{exec}}

La colonne `VERSION` affiche le label `version` de chaque pod. Note les IP des pods.

`kubectl get svc lightsaber -o wide`{{exec}}

La colonne `SELECTOR` affiche `app=lightsaber,version=blue` : seuls les pods blue reçoivent le trafic.

`curl http://jedi-temple:30080`{{exec}}

Réponse attendue : `Sabre laser - version blue`.

## 2. Basculer le Service sur green

En blue/green, basculer revient à changer le selector du Service :

`kubectl patch service lightsaber -p '{"spec":{"selector":{"version":"green"}}}'`{{exec}}

Seule la clé `version` change : `app: lightsaber` est conservée.

> Même résultat avec `kubectl edit service lightsaber` : dans `spec.selector`, remplace `version: blue` par `version: green`.

## 3. Vérifier la bascule

`kubectl get svc lightsaber -o wide`{{exec}}

Le selector vaut maintenant `app=lightsaber,version=green`.

`kubectl get endpointslices -l kubernetes.io/service-name=lightsaber`{{exec}}

La colonne `ENDPOINTS` contient les IP des pods green :

`kubectl get pods -l version=green -o wide`{{exec}}

Appelle le Service plusieurs fois :

```
for i in $(seq 1 6); do curl -s http://jedi-temple:30080; done
```{{exec}}

Chaque réponse doit être `Sabre laser - version green`.

## 4. Constater que blue est toujours là

`kubectl get deployments`{{exec}}

Les pods blue tournent toujours, ils ne reçoivent simplement plus de trafic. **Ne les supprime pas** : c'est ce qui rendra le retour arrière immédiat à l'étape suivante.
