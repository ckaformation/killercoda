# Bravo !

Tu as parcouru les fondamentaux du Service :

1. **Le problème** : l'IP d'un pod est éphémère ; un pod remplacé obtient une nouvelle adresse, et chaque réplica a la sienne.
2. **Le Service ClusterIP** : une adresse virtuelle et stable qui répartit les appels entre les pods dont les labels correspondent à son selector.
3. **La résilience** : après la suppression d'un pod, l'ancienne IP ne répond plus, mais le Service, lui, répond toujours : ses endpoints sont mis à jour automatiquement.
4. **Le DNS** : un pod peut appeler le Service par `echo-base`, `echo-base.default` ou `echo-base.default.svc.cluster.local`.
5. **Le NodePort** : le port 30080 est ouvert sur tous les nodes et redirige vers le Service, même sur un node qui n'héberge aucun pod.

## La nomenclature DNS à retenir

```
<service>.<namespace>.svc.<domaine-du-cluster>
```

Le nom court n'est valable que dans le même namespace ; depuis un autre namespace, utilise au minimum `<service>.<namespace>`.

## Ce qu'il faut retenir

- Un Service sélectionne des pods par **labels** (le `selector`) et non par leur nom ou leur Deployment.
- Les types de Service sont **cumulatifs** : un `NodePort` inclut un `ClusterIP`, et un `LoadBalancer` inclut un `NodePort`. Tu le verras avec MetalLB dans un autre scénario.
- Pour joindre une application depuis l'extérieur du cluster de façon plus riche (noms d'hôtes, chemins, TLS), on utilise un Ingress ou la Gateway API, qui s'appuient eux aussi sur des Services.

## Pour aller plus loin

- Documentation officielle des Services : https://kubernetes.io/docs/concepts/services-networking/service/
- DNS pour les Services et les Pods : https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
