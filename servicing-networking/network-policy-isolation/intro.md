# NetworkPolicy : isolation par défaut et exceptions ciblées

Bienvenue dans le premier scénario du chapitre Services & Networking ! Par défaut, dans Kubernetes, **tous les pods peuvent parler à tous les pods**, sans restriction, y compris entre namespaces différents. Les `NetworkPolicy` permettent de changer ça — à condition que le CNI du cluster les supporte.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud, avec **Calico** comme CNI (explicitement installé pour ce scénario : c'est un des CNI qui implémentent réellement les `NetworkPolicy` — tous ne le font pas).
- Deux namespaces applicatifs : **tatooine** et **alderaan**, qui peuvent aujourd'hui discuter librement entre eux, et en interne.
- Dans `tatooine` : deux pods, `luke` et `obi-wan` (tous deux capables de faire des `curl`, en plus de servir une page web basique).
- Dans `alderaan` : un pod, `leia`.
- Un raccourci `k` (identique à `kubectl`).

## Ce que tu vas faire

1. Écrire une `NetworkPolicy` de **deny par défaut** dans les deux namespaces, et constater qu'elle bloque même le trafic intra-namespace.
2. Autoriser précisément `luke` à joindre `obi-wan`, toujours en intra-namespace.
3. Autoriser précisément `luke` (et seulement lui) à joindre `leia`, dans l'autre namespace — avec une attention particulière portée à la syntaxe YAML du champ `from`, où `namespaceSelector` et `podSelector` peuvent signifier un **ET** ou un **OU** selon la façon dont ils sont indentés.

C'est parti !
