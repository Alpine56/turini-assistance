// Turini Assistance : branche l'écran Turini (turini_ecran.dart) sur le modèle du serveur de RustDesk.
// Copié dans flutter/lib/desktop/pages/ par turini/personnaliser.py, qui l'appelle depuis
// desktop_home_page.dart à la place de l'écran d'origine en mode réception seule.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/desktop/pages/turini_ecran.dart';
import 'package:flutter_hbb/desktop/pages/turini_intro.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class TuriniAccueil extends StatefulWidget {
  const TuriniAccueil({Key? key}) : super(key: key);

  @override
  State<TuriniAccueil> createState() => _TuriniAccueilState();
}

class _TuriniAccueilState extends State<TuriniAccueil> {
  bool _intro = true;

  @override
  void initState() {
    super.initState();
    imcomingOnlyHomeSize = kTuriniTaille;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      windowManager.setSize(getIncomingOnlyHomeSize());
    });
  }

  void _copier(String texte) {
    if (texte.isEmpty) return;
    Clipboard.setData(ClipboardData(text: texte));
    showToast('Copié');
  }

  @override
  Widget build(BuildContext context) {
    final model = gFFI.serverModel;
    return Stack(
      children: [
        // Garde le suivi de l'état du serveur (relevé chaque seconde par ce widget de RustDesk).
        const Offstage(child: OnlineStatusWidget()),
        ListenableBuilder(
          listenable: Listenable.merge([model.serverId, model.serverPasswd]),
          builder: (context, _) => Obx(
            () => Stack(children: [
              TuriniEcran(
                identifiant: model.serverId.text,
                code: model.serverPasswd.text,
                etat: switch (stateGlobal.svcStatus.value) {
                  SvcStatus.ready => EtatTurini.pret,
                  SvcStatus.connecting => EtatTurini.connexion,
                  SvcStatus.notReady => EtatTurini.horsLigne,
                },
                onCopierIdentifiant: () => _copier(model.serverId.text),
                onCopierCode: () => _copier(model.serverPasswd.text),
                onNouveauCode: () => bind.mainUpdateTemporaryPassword(),
              ),
              // Animation de démarrage, retirée dès que l'identifiant et le serveur sont prêts.
              if (_intro)
                TuriniIntro(
                  pret: stateGlobal.svcStatus.value == SvcStatus.ready &&
                      model.serverId.text.isNotEmpty,
                  onFini: () => setState(() => _intro = false),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}
