// Turini Assistance : vérification du code technicien. Le code n'est jamais dans l'application :
// seule son empreinte PBKDF2-SHA256 (sel aléatoire, calculée à la compilation par
// turini/personnaliser.py depuis le secret GitHub TURINI_CODE_TECHNICIEN) est dans turini_code.dart.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

Uint8List pbkdf2Sha256(List<int> code, List<int> sel, int iterations) {
  final hmac = Hmac(sha256, code);
  var u = hmac.convert([...sel, 0, 0, 0, 1]).bytes;
  final resultat = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < resultat.length; j++) {
      resultat[j] ^= u[j];
    }
  }
  return resultat;
}

List<int> _hex(String texte) => [
      for (var i = 0; i + 1 < texte.length; i += 2)
        int.parse(texte.substring(i, i + 2), radix: 16)
    ];

/// Vrai si [code] correspond à l'empreinte. Une empreinte vide (secret absent à la compilation)
/// ne laisse jamais entrer.
bool codeTechnicienValide(
    String code, String selHex, String empreinteHex, int iterations) {
  if (empreinteHex.isEmpty || code.isEmpty) return false;
  final attendu = _hex(empreinteHex);
  final calcule = pbkdf2Sha256(utf8.encode(code), _hex(selHex), iterations);
  if (calcule.length != attendu.length) return false;
  var difference = 0;
  for (var i = 0; i < attendu.length; i++) {
    difference |= calcule[i] ^ attendu[i];
  }
  return difference == 0;
}
