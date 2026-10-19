// Turini Assistance : animation de démarrage. Un carré bleu plein écran recule jusqu'à devenir le
// logo, puis une petite voiture parcourt les lacets du logo tant que l'application se prépare.
// Purement visuel : turini_accueil.dart dit quand tout est prêt (pret) et retire l'animation (onFini).

import 'dart:math' as math;
import 'dart:ui' show Tangent;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hbb/desktop/pages/turini_ecran.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TuriniIntro extends StatefulWidget {
  const TuriniIntro({Key? key, required this.pret, required this.onFini})
      : super(key: key);

  final bool pret;
  final VoidCallback onFini;

  @override
  State<TuriniIntro> createState() => _TuriniIntroState();
}

// Durées en secondes.
const _debutVoiture = 2.0;
const _tour = 2.4;
const _pause = 0.5;
const _fondu = 0.35;
// Sans serveur, l'écran Turini s'affiche quand même (avec son message d'erreur) après ces tours.
const _toursMax = 2;

double _borne(double v) => v.clamp(0.0, 1.0).toDouble();
double _avance(double t, double a, double b) => _borne((t - a) / (b - a));
double _sortie(double x) => 1 - math.pow(1 - x, 3).toDouble();
double _douce(double x) =>
    x < .5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3).toDouble() / 2;

class _TuriniIntroState extends State<TuriniIntro>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;
  double? _finDebut;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tic)..start();
  }

  void _tic(Duration ecoule) {
    final t = ecoule.inMicroseconds / 1e6;
    if (_finDebut == null && t >= _debutVoiture) {
      final tours = ((t - _debutVoiture) / (_tour + _pause)).floor();
      if (tours >= 1 && (widget.pret || tours >= _toursMax)) _finDebut = t;
    }
    if (_finDebut != null && t >= _finDebut! + _fondu) {
      _ticker.stop();
      widget.onFini();
      return;
    }
    setState(() => _t = t);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final opacite =
        _finDebut == null ? 1.0 : 1 - _avance(t, _finDebut!, _finDebut! + _fondu);
    final mot = _sortie(_avance(t, 1.4, 1.9));
    final textes = _sortie(_avance(t, 1.7, 2.1));
    final points = t < _debutVoiture
        ? 0
        : ((t - _debutVoiture) * 2.5).floor() % 4;
    return Opacity(
      opacity: opacite,
      child: Container(
        color: Colors.white,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PeintreIntro(t))),
            Positioned(
              left: 0,
              right: 0,
              top: 312,
              child: Opacity(
                opacity: mot,
                child: Transform.translate(
                  offset: Offset(0, (1 - mot) * 12),
                  child: SvgPicture.asset('assets/turini-mot.svg', height: 58),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 394,
              child: Opacity(
                opacity: textes,
                child: const Text(
                  'ASSISTANCE À DISTANCE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 11,
                      letterSpacing: 3,
                      color: TuriniCouleurs.bleu),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 420,
              child: Opacity(
                opacity: _sortie(_avance(t, _debutVoiture, _debutVoiture + .3)),
                child: Text(
                  'Démarrage en cours${'.' * points}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Barlow',
                      fontSize: 13,
                      color: TuriniCouleurs.discret),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Opacity(opacity: textes, child: const TuriniDamier()),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeintreIntro extends CustomPainter {
  _PeintreIntro(this.t);

  final double t;

  // Le logo, dessiné sur 100 × 100 comme infra/marque/favicon.svg.
  static final _route = Path()
    ..moveTo(20, 78)
    ..lineTo(66, 78)
    ..arcToPoint(const Offset(66, 56),
        radius: const Radius.circular(11), clockwise: false)
    ..lineTo(34, 56)
    ..arcToPoint(const Offset(34, 34), radius: const Radius.circular(11))
    ..lineTo(57, 34);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Le carré bleu recule jusqu'à la taille du logo.
    const tailleFinale = 120.0;
    final z = _douce(_avance(t, .35, 1.35));
    final echelleDebut = size.longestSide * 1.7 / 100;
    final echelle = echelleDebut + (tailleFinale / 100 - echelleDebut) * z;
    final centre = Offset(size.width / 2, 225);
    final debut = Offset(size.width / 2, size.height / 2);
    final c = Offset.lerp(debut, centre, z)!;
    canvas.save();
    canvas.translate(c.dx - 50 * echelle, c.dy - 50 * echelle);
    canvas.scale(echelle);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 100, 100), const Radius.circular(22)),
        Paint()..color = TuriniCouleurs.bleu);

    // 2. La route se dessine, puis le point jaune apparaît.
    final mesure = _route.computeMetrics().first;
    final trace = _sortie(_avance(t, .9, 1.5));
    if (trace > 0) {
      canvas.drawPath(
          mesure.extractPath(0, mesure.length * trace),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
    }
    final jaune = Paint()..color = TuriniCouleurs.phare;
    final rayon = 8 * _sortie(_avance(t, 1.3, 1.6));

    // 3. La voiture fait le tour, et le point jaune s'allume à son arrivée.
    if (t >= _debutVoiture) {
      final k = (t - _debutVoiture) % (_tour + _pause);
      if (k > _tour) {
        final h = _avance(k, _tour, _tour + _pause);
        canvas.drawCircle(const Offset(70, 34), 8 + 10 * h,
            Paint()..color = TuriniCouleurs.phare.withOpacity(.6 * (1 - h)));
      }
      canvas.drawCircle(const Offset(70, 34), rayon, jaune);
      final position =
          mesure.getTangentForOffset(mesure.length * _douce(_borne(k / _tour)))!;
      final apparition = k < .15
          ? k / .15
          : (k > _tour + _pause - .2 ? (_tour + _pause - k) / .2 : 1.0);
      _voiture(canvas, position, _borne(apparition));
    } else {
      canvas.drawCircle(const Offset(70, 34), rayon, jaune);
    }
    canvas.restore();
  }

  void _voiture(Canvas canvas, Tangent position, double opacite) {
    if (opacite <= 0) return;
    Paint p(Color c, [double o = 1]) =>
        Paint()..color = c.withOpacity(c.opacity * o * opacite);
    canvas.save();
    canvas.translate(position.position.dx, position.position.dy);
    canvas.rotate(-position.angle);
    canvas.scale(1.3);
    canvas.drawPath(
        Path()
          ..moveTo(6, -2.2)
          ..lineTo(17, -6)
          ..lineTo(17, 6)
          ..lineTo(6, 2.2)
          ..close(),
        p(TuriniCouleurs.phare, .35));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-6, -3.8, 12, 7.6), const Radius.circular(2.4)),
        p(TuriniCouleurs.rouge));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(.6, -3, 3, 6), const Radius.circular(1)),
        p(TuriniCouleurs.asphalte, .85));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4.6, -2.8, 2.2, 5.6), const Radius.circular(.8)),
        p(TuriniCouleurs.asphalte, .6));
    final phare = p(const Color(0xFFFFF3C4));
    canvas.drawCircle(const Offset(5.6, -2.6), .9, phare);
    canvas.drawCircle(const Offset(5.6, 2.6), .9, phare);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PeintreIntro ancien) => ancien.t != t;
}
