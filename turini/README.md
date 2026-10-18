# Turini Assistance

Client d'assistance à distance de Turini : [RustDesk](https://github.com/rustdesk/rustdesk)
personnalisé (nom, icônes, serveur et clé de Turini intégrés). Licence AGPL-3.0, comme RustDesk :
ce dépôt public contient tout le code du client distribué.

- `personnaliser.py` : les modifications, appliquées juste avant la compilation.
- `marque/` : icônes Turini.
- `.github/workflows/turini-windows.yml` : compilation Windows (onglet Actions, « Run workflow »,
  avec l'adresse du serveur et sa clé publique). L'exécutable sort en artefact
  `turini-assistance-windows`.

Mettre à jour avec RustDesk : « Sync fork » sur GitHub, puis relancer la compilation. Si RustDesk
a changé une ligne modifiée, `personnaliser.py` s'arrête et dit laquelle.
