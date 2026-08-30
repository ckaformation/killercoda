# Étape 1 — Passer le service de NodePort à LoadBalancer

## 1. Observer l'état actuel

`k get svc holonet`{{exec}}

Le type est `NodePort`, et la colonne `EXTERNAL-IP` est vide.

## 2. Changer le type du service

`kubectl edit svc holonet`{{exec}}

Change `type: NodePort` en `type: LoadBalancer`.

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 3. Observer l'attribution d'une IP externe

`watch kubectl get svc holonet`{{exec}}

La colonne `EXTERNAL-IP` doit passer de `<pending>` à une adresse de la plage gérée par MetalLB (vue dans l'intro). Quitte avec `Ctrl+C` une fois l'IP attribuée.

## 4. Vérifier que l'application répond

`EXTERNAL_IP=$(kubectl get svc holonet -o jsonpath='{.status.loadBalancer.ingress[0].ip}') && curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$EXTERNAL_IP"`{{exec}}

Tu dois obtenir `200` — sans passer par un port de nœud spécifique (`NodePort`) ni connaître d'IP de nœud : juste l'IP externe attribuée par MetalLB, exactement comme le ferait un vrai `LoadBalancer` cloud.
