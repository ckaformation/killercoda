# Troubleshooting NetworkPolicy

Bienvenue ! Contrairement au scénario précédent (`netpol-isolation`), ici on ne te guide pas commande par commande : deux `NetworkPolicy` sont **déjà en place, mais cassées**. À toi de diagnostiquer pourquoi, et de corriger.

Chaque étape propose :
- un **énoncé** décrivant le comportement attendu (et celui observé) ;
- un bouton **Tip**, si tu veux une piste sans la réponse ;
- un bouton **Solution**, avec la correction complète et son explication.

Essaie de résoudre chaque cas par toi-même avant de dérouler l'un ou l'autre.

## Ce qui est déjà en place

- Un cluster Kubernetes mono-nœud, CNI Cilium (supporte les `NetworkPolicy`).
- Quatre namespaces : **a**, **b**, **c**, **d**.
- Dans **a** : le pod `han`. Dans **b** : le pod `chewie`. Une `NetworkPolicy` dans `b` est censée autoriser `han` à le joindre — mais ça ne fonctionne pas.
- Dans **c** : le pod `lando`. Dans **d** : les pods `wedge` et `biggs`. Une `NetworkPolicy` dans `d` est censée autoriser à la fois le trafic venant de `c`, et le trafic entre les pods de `d` eux-mêmes — mais rien ne passe.
- Un raccourci `k` (identique à `kubectl`).

C'est parti !
