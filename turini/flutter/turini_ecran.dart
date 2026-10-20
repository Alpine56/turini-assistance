// Turini Assistance : écran d'accueil aux couleurs de Turini (logo, bleu, jaune, polices Barlow).
// Purement visuel : turini_accueil.dart lui fournit l'identifiant, le code et l'état du serveur.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum EtatTurini { pret, connexion, horsLigne }

class TuriniCouleurs {
  static const bleu = Color(0xFF12357A);
  static const bleuFonce = Color(0xFF0B2350);
  static const bleuPale = Color(0xFFE3E9F5);
  static const phare = Color(0xFFF2C230);
  static const asphalte = Color(0xFF14171C);
  static const neige = Color(0xFFF4F5F2);
  static const texte2 = Color(0xFF3F444C);
  static const discret = Color(0xFF5B616B);
  static const trait = Color(0xFFDADDD8);
  static const vert = Color(0xFF1E8E4F);
  static const orange = Color(0xFFD9822B);
  static const rouge = Color(0xFFC8102E);
}

const kTuriniTaille = Size(380, 530);

class TuriniEcran extends StatelessWidget {
  const TuriniEcran({
    Key? key,
    required this.identifiant,
    required this.code,
    required this.etat,
    required this.onCopierIdentifiant,
    required this.onCopierCode,
    required this.onNouveauCode,
    this.accesPermanent = false,
  }) : super(key: key);

  final String identifiant;
  final String code;
  final EtatTurini etat;
  final VoidCallback onCopierIdentifiant;
  final VoidCallback onCopierCode;
  final VoidCallback onNouveauCode;
  // Un technicien a posé un mot de passe permanent : le client doit le voir.
  final bool accesPermanent;

  static const _texte = TextStyle(
      fontFamily: 'Barlow', color: TuriniCouleurs.asphalte, fontSize: 14);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: _texte,
      child: Container(
        color: TuriniCouleurs.neige,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _entete(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Communiquez ces deux informations à votre technicien Turini.',
                      style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: TuriniCouleurs.texte2),
                    ),
                    const SizedBox(height: 16),
                    _Carte(
                      titre: 'Identifiant',
                      valeur: identifiant,
                      actions: [
                        _Action(
                            icone: Icons.copy_rounded,
                            aide: 'Copier',
                            onTap: onCopierIdentifiant),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Carte(
                      titre: "Code d'accès",
                      valeur: code,
                      actions: [
                        _Action(
                            icone: Icons.copy_rounded,
                            aide: 'Copier',
                            onTap: onCopierCode),
                        _Action(
                            icone: Icons.refresh_rounded,
                            aide: 'Nouveau code',
                            onTap: onNouveauCode),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Etat(etat: etat),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            _pied(),
          ],
        ),
      ),
    );
  }

  Widget _entete() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TuriniCouleurs.bleu, TuriniCouleurs.bleuFonce],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset('assets/turini-logo.svg', height: 44),
                const SizedBox(height: 14),
                const Text(
                  'ASSISTANCE À DISTANCE',
                  style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                      letterSpacing: 2.2,
                      color: TuriniCouleurs.phare),
                ),
                const SizedBox(height: 4),
                const Text(
                  'On vous dépanne, à distance.',
                  style: TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w800,
                      fontSize: 27,
                      height: 1.1,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          const TuriniDamier(),
        ],
      ),
    );
  }

  Widget _pied() {
    if (accesPermanent) {
      return Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
        color: TuriniCouleurs.orange.withOpacity(0.12),
        child: const Row(
          children: [
            Icon(Icons.key_rounded, size: 18, color: TuriniCouleurs.orange),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Accès permanent actif : votre technicien Turini peut se reconnecter '
                'sans code. Il le retire à la fin de l\'intervention.',
                style: TextStyle(
                    fontSize: 12, height: 1.35, color: TuriniCouleurs.asphalte),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: TuriniCouleurs.trait)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: TuriniCouleurs.bleu),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Ne donnez ce code qu'à un technicien Turini que vous avez contacté. "
              'Vous pouvez couper la connexion à tout moment.',
              style: TextStyle(
                  fontSize: 12, height: 1.35, color: TuriniCouleurs.discret),
            ),
          ),
        ],
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  const _Carte(
      {required this.titre, required this.valeur, required this.actions});

  final String titre;
  final String valeur;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TuriniCouleurs.trait),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 46,
            decoration: BoxDecoration(
              color: TuriniCouleurs.phare,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre.toUpperCase(),
                  style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10.5,
                      letterSpacing: 1.6,
                      color: TuriniCouleurs.discret),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  valeur.isEmpty ? '…' : valeur,
                  maxLines: 1,
                  style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 26,
                      letterSpacing: 1,
                      color: TuriniCouleurs.bleu),
                ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icone, required this.aide, required this.onTap});

  final IconData icone;
  final String aide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: aide,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icone, size: 20),
        color: TuriniCouleurs.bleu,
        hoverColor: TuriniCouleurs.bleuPale,
        splashRadius: 20,
      ),
    );
  }
}

class _Etat extends StatelessWidget {
  const _Etat({required this.etat});

  final EtatTurini etat;

  @override
  Widget build(BuildContext context) {
    final (couleur, texte) = switch (etat) {
      EtatTurini.pret => (
          TuriniCouleurs.vert,
          'Prêt : votre technicien peut se connecter.'
        ),
      EtatTurini.connexion => (
          TuriniCouleurs.orange,
          'Connexion au serveur Turini…'
        ),
      EtatTurini.horsLigne => (
          TuriniCouleurs.rouge,
          'Serveur Turini injoignable. Vérifiez votre connexion Internet.'
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texte,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: couleur)),
          ),
        ],
      ),
    );
  }
}

/// Bande à damier, comme la ligne d'arrivée du site et de la présentation.
class TuriniDamier extends StatelessWidget {
  const TuriniDamier({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 8, child: CustomPaint(painter: _PeintreDamier()));
  }
}

class _PeintreDamier extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cote = 4.0;
    final blanc = Paint()..color = Colors.white;
    final noir = Paint()..color = TuriniCouleurs.asphalte;
    for (var x = 0.0; x < size.width; x += cote) {
      for (var y = 0.0; y < size.height; y += cote) {
        final pair = ((x / cote).round() + (y / cote).round()) % 2 == 0;
        canvas.drawRect(
            Rect.fromLTWH(x, y, cote, cote), pair ? blanc : noir);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
