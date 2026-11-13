# Troubleshooting StatefulSet, drain de nœud & affinité de volume

Un `StatefulSet` `clone-vat` tourne dans le namespace `kamino`, sur
`node01`.

Tu vas devoir préparer ce nœud pour une opération de maintenance, puis
comprendre — en deux temps — pourquoi le pod refuse de redémarrer
ailleurs.

Le cluster se prépare en arrière-plan pendant que tu lis ces lignes.
