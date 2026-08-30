# Étape 1 — Passer le service de NodePort à LoadBalancer

## 1. Observer l'état actuel

`k get svc holonet -n holonet -o yaml`{{exec}}

Le type est `NodePort`, la colonne `EXTERNAL-IP` est vide, et chaque port porte un `nodePort` attribué automatiquement.

## 2. Changer le type du service

`kubectl edit svc holonet -n holonet`{{exec}}

Trois modifications à apporter :

1. Change `type: NodePort` en `type: LoadBalancer`.
2. Supprime la ligne `nodePort: <valeur>` sous `ports:` (héritée de l'ancien type, elle n'a plus lieu d'être).
3. Ajoute `allocateLoadBalancerNodePorts: false` dans `spec` (au même niveau que `type`, `ports`, `selector`) : ça empêche Kubernetes de réattribuer un NodePort par défaut, pour un service purement `LoadBalancer`.

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## 3. Observer l'attribution d'une IP externe

`watch kubectl get svc holonet -n holonet`{{exec}}

La colonne `EXTERNAL-IP` doit passer de `<pending>` à une adresse de la plage gérée par MetalLB (vue dans l'intro). Quitte avec `Ctrl+C` une fois l'IP attribuée.

## 4. Vérifier que l'application répond

`EXTERNAL_IP=$(kubectl get svc holonet -n holonet -o jsonpath='{.status.loadBalancer.ingress[0].ip}') && curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$EXTERNAL_IP"`{{exec}}

Tu dois obtenir `200` — sans passer par un port de nœud spécifique (`NodePort`) ni connaître d'IP de nœud : juste l'IP externe attribuée par MetalLB, exactement comme le ferait un vrai `LoadBalancer` cloud.
