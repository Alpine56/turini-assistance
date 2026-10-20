// Turini Assistance : menu technicien caché (Ctrl+Maj+T sur l'écran Turini), ouvert seulement avec le
// code technicien Turini. Il permet, pendant une intervention, de poser un mot de passe permanent,
// d'installer le logiciel sur le poste, puis de tout remettre en mode client.
// Le client garde l'écran simple : il ne voit ni ce menu ni les réglages de RustDesk.

import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/desktop/pages/turini_code.dart';
import 'package:flutter_hbb/desktop/pages/turini_ecran.dart';
import 'package:flutter_hbb/desktop/pages/turini_secret.dart';
import 'package:flutter_hbb/models/platform_model.dart';

const _essaisMax = 5;
var _echecs = 0;

bool get menuTechnicienDisponible => kTuriniEmpreinte.isNotEmpty;

/// Demande le code technicien, puis ouvre le menu. [auRetour] est appelé quand le menu se ferme,
/// pour que l'écran Turini relise l'état de l'accès permanent.
Future<void> ouvrirMenuTechnicien(
    BuildContext context, VoidCallback auRetour) async {
  if (!menuTechnicienDisponible) return;
  final ok = await showDialog<bool>(
        context: context,
        builder: (_) => const _DemandeCode(),
      ) ??
      false;
  if (!ok || !context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _MenuTechnicien(),
  );
  auRetour();
}

class _Cadre extends StatelessWidget {
  const _Cadre({required this.titre, required this.enfants});

  final String titre;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TuriniCouleurs.neige,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: DefaultTextStyle(
        style: const TextStyle(
            fontFamily: 'Barlow', fontSize: 13, color: TuriniCouleurs.asphalte),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                titre.toUpperCase(),
                style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    letterSpacing: 1.6,
                    color: TuriniCouleurs.bleu),
              ),
              const SizedBox(height: 12),
              ...enfants,
            ],
          ),
        ),
      ),
    );
  }
}

Widget _champ(TextEditingController c, String libelle,
        {ValueChanged<String>? valider, FocusNode? focus}) =>
    TextField(
      controller: c,
      focusNode: focus,
      obscureText: true,
      autofocus: valider != null,
      onSubmitted: valider,
      style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        labelText: libelle,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: TuriniCouleurs.bleu, width: 2)),
        floatingLabelStyle: const TextStyle(color: TuriniCouleurs.bleu),
      ),
    );

Widget _bouton(String texte, VoidCallback? action,
        {Color couleur = TuriniCouleurs.bleu}) =>
    ElevatedButton(
      onPressed: action,
      style: ElevatedButton.styleFrom(
        backgroundColor: couleur,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
            fontFamily: 'Barlow', fontWeight: FontWeight.w600, fontSize: 13),
      ),
      child: Text(texte),
    );

Widget _ligne(String texte, Color couleur) => texte.isEmpty
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(texte, style: TextStyle(color: couleur, fontSize: 12.5)),
      );

class _DemandeCode extends StatefulWidget {
  const _DemandeCode();

  @override
  State<_DemandeCode> createState() => _DemandeCodeState();
}

class _DemandeCodeState extends State<_DemandeCode> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  var _verification = false;
  var _erreur = '';

  Future<void> _valider([String? _]) async {
    if (_verification || _echecs >= _essaisMax) return;
    final code = _code.text;
    setState(() => _verification = true);
    final ok = await Isolate.run(() => codeTechnicienValide(
        code, kTuriniSel, kTuriniEmpreinte, kTuriniIterations));
    if (!mounted) return;
    if (ok) {
      _echecs = 0;
      Navigator.of(context).pop(true);
      return;
    }
    _echecs++;
    _code.clear();
    setState(() {
      _verification = false;
      _erreur = _echecs >= _essaisMax
          ? 'Menu bloqué jusqu\'au prochain démarrage du logiciel.'
          : 'Code incorrect.';
    });
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloque = _echecs >= _essaisMax;
    return _Cadre(titre: 'Technicien Turini', enfants: [
      if (!bloque) _champ(_code, 'Code technicien', valider: _valider, focus: _focus),
      _ligne(_erreur, TuriniCouleurs.rouge),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: TuriniCouleurs.discret),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 8),
          if (!bloque)
            _bouton(_verification ? 'Vérification…' : 'Valider',
                _verification ? null : _valider),
        ],
      ),
    ]);
  }
}

class _MenuTechnicien extends StatefulWidget {
  const _MenuTechnicien();

  @override
  State<_MenuTechnicien> createState() => _MenuTechnicienState();
}

class _MenuTechnicienState extends State<_MenuTechnicien> {
  final _mdp = TextEditingController();
  final _confirmation = TextEditingController();
  var _permanent = false;
  var _installe = false;
  var _message = '';
  var _erreur = '';

  @override
  void initState() {
    super.initState();
    _relire();
  }

  Future<void> _relire() async {
    final permanent =
        await bind.mainGetCommon(key: 'permanent-password-set') == 'true';
    final installe = bind.mainIsInstalled();
    if (mounted) {
      setState(() {
        _permanent = permanent;
        _installe = installe;
      });
    }
  }

  void _dire({String message = '', String erreur = ''}) =>
      setState(() {
        _message = message;
        _erreur = erreur;
      });

  Future<void> _poserMotDePasse() async {
    final mdp = _mdp.text;
    if (mdp.length < 8) {
      _dire(erreur: 'Au moins 8 caractères.');
      return;
    }
    if (mdp != _confirmation.text) {
      _dire(erreur: 'Les deux saisies sont différentes.');
      return;
    }
    if (!await bind.mainSetPermanentPasswordWithResult(password: mdp)) {
      _dire(erreur: 'Le mot de passe n\'a pas été enregistré.');
      return;
    }
    await bind.mainSetOption(
        key: 'verification-method', value: 'use-both-passwords');
    _mdp.clear();
    _confirmation.clear();
    await _relire();
    _dire(message: 'Accès permanent actif.');
  }

  Future<void> _installer() async {
    _dire(
        message:
            'Installation lancée : faites accepter la fenêtre Windows au client.');
    await bind.installInstallMe(
        options: ' startmenu', path: bind.installInstallPath());
  }

  Future<void> _finIntervention() async {
    await bind.mainSetPermanentPasswordWithResult(password: '');
    await bind.mainSetOption(
        key: 'verification-method', value: 'use-temporary-password');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _mdp.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const intertitre = TextStyle(fontWeight: FontWeight.w600, fontSize: 14);
    return _Cadre(titre: 'Menu technicien', enfants: [
      const Text('Accès permanent', style: intertitre),
      const SizedBox(height: 4),
      Text(_permanent
          ? 'Actif : vous pouvez vous reconnecter avec le mot de passe permanent.'
          : 'Inactif : seul le code à usage unique fonctionne.'),
      const SizedBox(height: 8),
      _champ(_mdp, 'Mot de passe permanent'),
      const SizedBox(height: 8),
      _champ(_confirmation, 'Confirmation'),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: _bouton(
            _permanent ? 'Changer le mot de passe' : 'Activer',
            _poserMotDePasse),
      ),
      const Divider(height: 24),
      const Text('Installation sur ce poste', style: intertitre),
      const SizedBox(height: 4),
      Text(_installe
          ? 'Installé : le poste reste joignable après un redémarrage. '
              'Pour le retirer : Paramètres Windows, Applications.'
          : 'Non installé : après un redémarrage, le client devra relancer '
              'Turini Assistance.'),
      if (!_installe) ...[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: _bouton('Installer', _installer),
        ),
      ],
      _ligne(_message, TuriniCouleurs.vert),
      _ligne(_erreur, TuriniCouleurs.rouge),
      const Divider(height: 24),
      Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: TuriniCouleurs.discret),
            child: const Text('Fermer'),
          ),
          const Spacer(),
          _bouton('Fin d\'intervention', _finIntervention,
              couleur: TuriniCouleurs.asphalte),
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        'Fin d\'intervention : retire le mot de passe permanent, seul le code à usage unique reste.',
        style: TextStyle(fontSize: 11.5, color: TuriniCouleurs.discret),
      ),
    ]);
  }
}
