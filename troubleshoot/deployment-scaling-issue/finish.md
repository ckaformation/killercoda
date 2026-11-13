# Bravo !

Tu as :

- Créé un `HorizontalPodAutoscaler` avec `kubectl autoscale`.
- Diagnostiqué un `ResourceQuota` limitant silencieusement le nombre
  de pods dans un namespace, empêchant le HPA d'atteindre son minimum.
- Généré une vraie charge CPU via `kubectl exec` + `stress`, et
  observé le HPA scaler en conséquence, en temps réel, via
  `kubectl get hpa -w` et `kubectl top pod`.

## Pour aller plus loin

- `kubectl describe hpa` : regarde la section `Events`, elle raconte
  toute l'histoire du scaling (raisons des décisions prises).
- Arrête les process `stress` (ou attends l'expiration naturelle) et
  observe le délai avant que le HPA ne redescende — le
  `stabilizationWindow` par défaut pour le scale-down est
  volontairement prudent.
- Que se passerait-il avec un `limits.cpu` de namespace plus bas que
  50m × 20 pods ? Cette fois, ce serait bien le quota CPU, et non le
  nombre de pods, qui bloquerait le scaling.
