# Turini Assistance

Client d'assistance à distance de Turini : [RustDesk](https://github.com/rustdesk/rustdesk)
personnalisé (nom, icônes, serveur et clé de Turini intégrés). Licence AGPL-3.0, comme RustDesk :
ce dépôt public contient tout le code du client distribué.

- `personnaliser.py` : les modifications, appliquées juste avant la compilation.
- `marque/` : icônes et logo Turini, polices du site (`polices/`, SIL Open Font License).
- `flutter/` : écran d'accueil Turini (`turini_ecran.dart` pour le dessin, `turini_accueil.dart`
  pour le branchement), copié dans `flutter/lib/desktop/pages/` à la compilation. À chaque
  démarrage, `turini_intro.dart` joue l'animation Turini (le carré bleu devient le logo, une voiture
  parcourt ses lacets) jusqu'à ce que l'identifiant et le serveur soient prêts.
- `lanceur/` : fenêtre affichée pendant que le lanceur décompresse l'application (premier lancement
  et après une mise à jour). `ui.rs` remplace celui de RustDesk, `demarrage.gif` est l'animation.
- Réglages verrouillés (`REGLAGES` dans `personnaliser.py`) : réception seule, aucun réglage
  visible, pas d'installation, code d'accès à usage unique, pas de modification des réglages à
  distance, pas d'annonce sur le réseau local ni d'accès direct par IP.
- Menu technicien (`flutter/turini_technicien.dart`) : Ctrl+Maj+T sur l'écran Turini, puis le code
  technicien. Il pose un mot de passe permanent, installe le logiciel sur le poste (pour le retrouver
  après un redémarrage) et « Fin d'intervention » remet le code à usage unique seul. Le client voit un
  bandeau tant qu'un accès permanent est actif. Le code vient du secret GitHub
  `TURINI_CODE_TECHNICIEN` (12 caractères au moins) : seule son empreinte PBKDF2-SHA256 entre dans
  l'application (`turini_code.dart`, généré). Sans ce secret, le menu est désactivé. Cinq codes faux
  bloquent le menu jusqu'au redémarrage du logiciel.
- Raccourci sur le bureau : `libs/portable/src/turini_bureau.rs`. Au premier lancement, le logiciel se
  recopie dans le dossier de l'utilisateur (`Turini\Assistance` sous `%LOCALAPPDATA%`) et pose
  « Turini Assistance » sur le bureau, sans service ni droits administrateur.
- `.github/workflows/turini-windows.yml` : compilation Windows (onglet Actions, « Run workflow »,
  avec l'adresse du serveur et sa clé publique). L'exécutable sort en artefact
  `turini-assistance-windows`, et une version GitHub `v<date>.<n>` est publiée avec
  `turini-assistance.exe` et sa fiche `turini-assistance.txt` (version, adresse, empreinte).
  L'étape « Alléger Turini Assistance » retire ce qui ne sert pas au client dépanné (imprimante
  à distance, écran virtuel).
- Mise à jour au démarrage : `libs/portable/src/turini_maj.rs`. Le lanceur lit la fiche publiée sur le
  site de Turini (entrée `maj` de la compilation) et propose la nouvelle version si elle existe.

Mettre à jour avec RustDesk : « Sync fork » sur GitHub, puis relancer la compilation. Si RustDesk
a changé une ligne modifiée, `personnaliser.py` s'arrête et dit laquelle.
