# Cas 1 — han ne parvient pas à joindre chewie

## Contexte

`han` (namespace `dagobah`) doit pouvoir joindre `chewie` (namespace `endor`) sur le port 80. Une `NetworkPolicy`, `allow-from-dagobah`, existe déjà dans le namespace `endor` et semble prévue exactement pour ça — mais la connexion échoue.

## Constater le problème

`k get pods -A -o wide`{{exec}}

`k get networkpolicy -n endor allow-from-dagobah -o yaml`{{exec}}

`CHEWIE_IP=$(kubectl get pod chewie -n endor -o jsonpath='{.status.podIP}') && kubectl exec han -n dagobah -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$CHEWIE_IP"`{{exec}}

La commande `curl` ci-dessus échoue (timeout, pas de code HTTP).

## À toi de jouer

Examine la `NetworkPolicy` `allow-from-dagobah` dans le namespace `endor`, et corrige ce qui doit l'être — **en modifiant la NetworkPolicy**, pas les namespaces.

<details>
<summary>💡 Tip</summary>

Regarde les labels réellement présents sur le namespace `dagobah` :

`k get namespace dagobah --show-labels`{{exec}}

Compare avec ce que la `NetworkPolicy` attend dans son `namespaceSelector.matchLabels`.

</details>

<details>
<summary>✅ Solution</summary>

Le namespace `dagobah` porte le label `project: alpha` — mais la `NetworkPolicy` cherche `project: beta` dans son `namespaceSelector` :

```yaml
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            project: beta   # <- ne correspond à rien : aucun namespace n'a ce label
```

La correction consiste à remplacer `beta` par `alpha` :

`kubectl edit networkpolicy allow-from-dagobah -n endor`{{exec}}

```yaml
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            project: alpha
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

`CHEWIE_IP=$(kubectl get pod chewie -n endor -o jsonpath='{.status.podIP}') && kubectl exec han -n dagobah -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$CHEWIE_IP"`{{exec}}

Tu dois maintenant obtenir `200`.

</details>
