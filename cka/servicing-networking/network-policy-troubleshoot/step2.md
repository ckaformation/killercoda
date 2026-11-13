# Cas 2 — Communications bloquées dans mustafar

## Contexte

Dans le namespace `mustafar`, deux pods : `wedge` et `biggs`. Une `NetworkPolicy`, `allow-kamino-and-mustafar-internal`, doit autoriser sur le port 80 :

- le trafic venant de **n'importe quel pod du namespace `kamino`** (ici, `lando`) ;
- **et séparément**, le trafic entre pods de `mustafar` portant le label `squad: rebel` (pour que `wedge` et `biggs` puissent se joindre l'un l'autre).

Ces deux critères doivent se cumuler en **OU** : n'importe laquelle des deux conditions suffit à autoriser la connexion. Actuellement, ni `lando` ne peut joindre `wedge`, ni `wedge` ne peut joindre `biggs`.

## Constater le problème

`k get networkpolicy -n mustafar allow-kamino-and-mustafar-internal -o yaml`{{exec}}

`WEDGE_IP=$(kubectl get pod wedge -n mustafar -o jsonpath='{.status.podIP}') && kubectl exec lando -n kamino -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$WEDGE_IP"`{{exec}}

`BIGGS_IP=$(kubectl get pod biggs -n mustafar -o jsonpath='{.status.podIP}') && kubectl exec wedge -n mustafar -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$BIGGS_IP"`{{exec}}

Les deux commandes échouent.

## À toi de jouer

Réécris la `NetworkPolicy` `allow-kamino-and-mustafar-internal` pour qu'elle se comporte comme décrit dans le contexte ci-dessus.

<details>
<summary>💡 Tip</summary>

Commence par vérifier que les labels utilisés par la policy correspondent bien à la réalité :

`k get pods -n mustafar --show-labels`{{exec}}

Une fois ce point écarté, regarde de près comment `namespaceSelector` et `podSelector` sont positionnés l'un par rapport à l'autre, dans le champ `from` de la règle `ingress` actuelle. Dans YAML, la même paire de sélecteurs peut signifier deux choses très différentes selon un seul niveau d'indentation :

- **au même niveau, dans le même élément de la liste** (un seul tiret `-` pour les deux) → logique **ET** : il faut satisfaire les deux conditions à la fois.
- **dans deux éléments séparés de la liste** (un tiret `-` pour chacun) → logique **OU** : l'une ou l'autre des conditions suffit.

</details>

<details>
<summary>✅ Solution</summary>

Les labels sont corrects (`wedge` et `biggs` portent bien `squad: rebel`, et la policy cherche bien cette valeur) — le problème n'est pas là. Le vrai problème : `namespaceSelector` et `podSelector` sont combinés **dans le même élément** de la liste `from`, ce qui les met en **ET** :

```yaml
# Version actuelle (fausse) : ET
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: kamino
        podSelector:
          matchLabels:
            squad: rebel
    ports:
      - protocol: TCP
        port: 80
```

Avec cette syntaxe, un pod source devrait être **à la fois** dans le namespace `kamino` **et** porter le label `squad: rebel` — une combinaison qu'aucun pod ne remplit jamais (`lando`, dans `kamino`, n'a pas ce label ; `wedge` et `biggs`, qui l'ont, ne sont pas dans `kamino`). Résultat : rien ne passe jamais, dans aucun des deux sens voulus.

La correction : séparer les deux sélecteurs en deux éléments distincts de la liste `from`, pour obtenir un **OU** — sans toucher à la valeur du `podSelector`, qui était déjà correcte :

```yaml
# Version corrigée : OU (deux éléments séparés)
ingress:
  - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: kamino
      - podSelector:
          matchLabels:
            squad: rebel
    ports:
      - protocol: TCP
        port: 80
```

Remarque l'indentation : dans la version corrigée, `podSelector` a son propre tiret `-`, au même niveau que `namespaceSelector` — ce ne sont plus deux clés du même objet, mais deux éléments distincts de la liste.

`kubectl edit networkpolicy allow-kamino-and-mustafar-internal -n mustafar`{{exec}}

Applique ce changement d'indentation (rien d'autre à modifier).

Sauvegarde et quitte : `Échap`, puis `:wq`, puis `Entrée`.

## Vérifier

`WEDGE_IP=$(kubectl get pod wedge -n mustafar -o jsonpath='{.status.podIP}') && kubectl exec lando -n kamino -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$WEDGE_IP"`{{exec}}

`BIGGS_IP=$(kubectl get pod biggs -n mustafar -o jsonpath='{.status.podIP}') && kubectl exec wedge -n mustafar -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 "http://$BIGGS_IP"`{{exec}}

Les deux doivent maintenant répondre `200`.

</details>
