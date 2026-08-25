# Bravo !

Tu viens d'explorer les `PriorityClass` et la préemption de pods :

1. **Comparer des priorités** : identifier, entre deux pods, celui qui a la priorité la plus haute — en Kubernetes, c'est toujours la valeur numérique la plus élevée qui l'emporte.
2. **Préemption réelle** : créé un pod de priorité supérieure (`flagship`, `level3`) demandant la même quantité de mémoire qu'un pod déjà en place (`star-destroyer`, `level2`) sur un nœud qui n'avait plus la place pour les deux — Kubernetes a supprimé le moins prioritaire pour faire de la place au plus prioritaire.

## Points clés à retenir

- Une `PriorityClass` est un objet cluster-wide ; sa `value` (un entier) détermine la priorité — plus la valeur est haute, plus la priorité l'est aussi.
- La préemption ne se déclenche que quand c'est **nécessaire** : un pod de haute priorité qui trouve de la place normalement ne préempte rien. C'est un mécanisme de dernier recours, pas un passe-droit systématique.
- Seuls les pods de priorité **strictement inférieure** à celle du pod en attente peuvent être préemptés — jamais un pod de priorité égale ou supérieure.
- La préemption est un événement observable : `kubectl get events` et `kubectl describe pod` documentent précisément ce qui a été sacrifié et pourquoi.

## Pour aller plus loin

- Pod Priority and Preemption : https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/
