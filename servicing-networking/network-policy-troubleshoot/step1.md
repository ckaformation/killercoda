# Cas 1 — matchLabels erroné entre les namespaces a et b

## Contexte

`han` (namespace `a`) doit pouvoir joindre `chewie` (namespace `b`) sur le port 80. Une `NetworkPolicy`, `allow-from-a`, existe déjà dans le namespace `b` et semble prévue exactement pour ça — mais la connexion échoue.

## Constater le problème

`k get pods -A -o wide`{{exec}}

`k get networkpolicy -n b allow-from-a -o yaml`{{exec}}

`CHEWIE_IP=$(kubectl get pod chewie -n b -o jsonpath='{.status.podIP}') && kubectl exec han -n a -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$CHEWIE_IP"`{{exec}}

La commande `curl` ci-dessus échoue (timeout, pas de code HTTP).

## À toi de jouer

Examine la `NetworkPolicy` `allow-from-a` dans le namespace `b`, compare-la à ce qui existe réellement sur le namespace `a`, et corrige ce qui doit l'être — **en modifiant la NetworkPolicy**, pas les namespaces.

<details>
<summary>💡 Tip</summary>

Regarde les labels réellement présents sur le namespace `a` :

`k get namespace a --show-labels`{{exec}}

Compare avec ce que la `NetworkPolicy` attend dans son `namespaceSelector.matchLabels`. Une valeur ne correspond pas.

</details>

<details>
<summary>✅ Solution</summary>

Le namespace `a` porte le label `project: alpha` — mais la `NetworkPolicy` cherche `project: beta` dans son `namespaceSelector` :

```yaml
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            project: beta   # <- ne correspond à rien : aucun namespace n'a ce label
```

La correction consiste à remplacer `beta` par `alpha` :

`kubectl edit networkpolicy allow-from-a -n b`{{exec}}

```yaml
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            project: alpha
```

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

`CHEWIE_IP=$(kubectl get pod chewie -n b -o jsonpath='{.status.podIP}') && kubectl exec han -n a -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$CHEWIE_IP"`{{exec}}

Tu dois maintenant obtenir `200`.

</details>
