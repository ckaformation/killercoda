# Étape 1 — Trois erreurs, une méthode

`kube-apiserver` ne démarre pas. Utilise la méthodologie vue
précédemment (`crictl`, `/var/log`, `journalctl -u kubelet`) pour
identifier et corriger les **3 erreurs** présentes dans
`/etc/kubernetes/manifests/kube-apiserver.yaml`.

```
crictl ps -a
```{{exec}}

```
journalctl -u kubelet --no-pager | tail -100
```{{exec}}

<details>
<summary>💡 Indice — erreur 1</summary>

Le fichier manifest est-il un YAML valide ?

</details>

<details>
<summary>💡 Indice — erreur 2</summary>

Une fois le pod capable de démarrer, regarde attentivement chaque
argument passé à `kube-apiserver`.

</details>

<details>
<summary>💡 Indice — erreur 3</summary>

Le certificat TLS référencé existe-t-il vraiment, à l'endroit indiqué ?

</details>

<details>
<summary>✅ Solution</summary>

Ces 3 erreurs se révèlent probablement l'une après l'autre : corriger
la première permet à kubelet de charger le fichier, ce qui fait
apparaître la seconde, et ainsi de suite.

**Erreur 1 — `metadata;` au lieu de `metadata:`**

Tant que cette erreur est présente, kubelet ne peut même pas charger
le fichier comme un pod valide — `journalctl -u kubelet` doit montrer
une erreur de parsing YAML explicite, et non un problème de conteneur.

```
sed -i 's/^metadata;$/metadata:/' /etc/kubernetes/manifests/kube-apiserver.yaml
```{{exec}}

**Erreur 2 — argument inconnu `--midichlorians=9000`**

Une fois le fichier valide, le conteneur `kube-apiserver` se crée mais
crashe immédiatement. `crictl ps -a` puis `crictl logs <id>` montrent
un rejet de l'argument au démarrage.

```
sed -i '/--midichlorians=9000/d' /etc/kubernetes/manifests/kube-apiserver.yaml
```{{exec}}

**Erreur 3 — `--tls-cert-file` pointe vers un fichier inexistant**

Une fois l'argument retiré, le process démarre mais échoue au
chargement du certificat TLS.

```
sed -i 's#--tls-cert-file=.*#--tls-cert-file=/etc/kubernetes/pki/apiserver.crt#' /etc/kubernetes/manifests/kube-apiserver.yaml
```{{exec}}

Une fois les 3 corrections faites, observe le retour à la normale :

```
watch crictl ps
```{{exec}}

(Ctrl+C pour sortir du `watch` une fois `kube-apiserver` stable.)

</details>
