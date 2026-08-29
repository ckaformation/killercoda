# Cas 2 — Logique ET au lieu de OU entre les namespaces c et d

## Contexte

Dans le namespace `d`, deux pods : `wedge` et `biggs`. Une `NetworkPolicy`, `allow-c-and-d-internal`, doit autoriser sur le port 80 :

- le trafic venant de **n'importe quel pod du namespace `c`** (ici, `lando`) ;
- **et séparément**, le trafic entre pods de `d` portant le label `squad: rebel` (pour que `wedge` et `biggs` puissent se joindre l'un l'autre).

Ces deux critères doivent se cumuler en **OU** : n'importe laquelle des deux conditions suffit à autoriser la connexion. Actuellement, ni `lando` ne peut joindre `wedge`, ni `wedge` ne peut joindre `biggs`.

## Constater le problème

`k get networkpolicy -n d allow-c-and-d-internal -o yaml`{{exec}}

`WEDGE_IP=$(kubectl get pod wedge -n d -o jsonpath='{.status.podIP}') && kubectl exec lando -n c -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$WEDGE_IP"`{{exec}}

`BIGGS_IP=$(kubectl get pod biggs -n d -o jsonpath='{.status.podIP}') && kubectl exec wedge -n d -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$BIGGS_IP"`{{exec}}

Les deux commandes échouent.

## À toi de jouer

Réécris la `NetworkPolicy` `allow-c-and-d-internal` pour qu'elle exprime correctement les deux critères en **OU**, avec les bonnes valeurs de labels.

<details>
<summary>💡 Tip</summary>

Dans le champ `from` d'une règle `ingress`, la façon dont `namespaceSelector` et `podSelector` sont indentés change tout :

- **au même niveau, dans le même élément de la liste** (un seul tiret `-` pour les deux) → logique **ET** : il faut satisfaire les deux conditions à la fois.
- **dans deux éléments séparés de la liste** (un tiret `-` pour chacun) → logique **OU** : l'une ou l'autre des conditions suffit.

Regarde comment la `NetworkPolicy` actuelle est structurée à ce niveau-là — et vérifie aussi la valeur du `podSelector` : le label qu'elle cherche existe-t-il vraiment sur `wedge` et `biggs` ?

`k get pods -n d --show-labels`{{exec}}

</details>

<details>
<summary>✅ Solution</summary>

Deux problèmes cumulés dans la version actuelle :

1. `namespaceSelector` et `podSelector` sont combinés **dans le même élément** de la liste `from` (logique ET), alors qu'on veut du OU.
2. Le `podSelector` cherche `squad: empire`, alors que `wedge` et `biggs` portent `squad: rebel`.

```yaml
# Version actuelle (fausse) : ET, et mauvaise valeur
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: c
        podSelector:
          matchLabels:
            squad: empire
    ports:
      - protocol: TCP
        port: 80
```

```yaml
# Version corrigée : OU (deux éléments séparés), bonne valeur
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: c
      - podSelector:
          matchLabels:
            squad: rebel
    ports:
      - protocol: TCP
        port: 80
```

Remarque l'indentation : dans la version corrigée, `podSelector` a son propre tiret `-`, au même niveau que `namespaceSelector` — ce ne sont plus deux clés du même objet, mais deux éléments distincts de la liste.

`kubectl edit networkpolicy allow-c-and-d-internal -n d`{{exec}}

Applique les deux changements ci-dessus (l'indentation du `podSelector`, et `empire` → `rebel`).

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## Vérifier

`WEDGE_IP=$(kubectl get pod wedge -n d -o jsonpath='{.status.podIP}') && kubectl exec lando -n c -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$WEDGE_IP"`{{exec}}

`BIGGS_IP=$(kubectl get pod biggs -n d -o jsonpath='{.status.podIP}') && kubectl exec wedge -n d -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$BIGGS_IP"`{{exec}}

Les deux doivent maintenant répondre `200`.

</details>
