#!/usr/bin/env python3
"""Personnalise RustDesk en « Turini Assistance » juste avant la compilation.

    python3 turini/personnaliser.py <adresse du serveur> <clé publique du serveur>

Appliqué par .github/workflows/turini-windows.yml sur une copie fraîche des sources : le dépôt
reste identique à RustDesk (hors dossier turini/ et ce flux), ce qui garde les mises à jour faciles.
Chaque remplacement doit trouver exactement son texte d'origine : si RustDesk change ces lignes,
le script s'arrête au lieu de produire un client à moitié personnalisé.

RustDesk est sous licence AGPL-3.0 : le code de ce client (ce dépôt) reste public.
"""

import re
import shutil
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
MARQUE = RACINE / "turini" / "marque"
NOM = "Turini"  # nom de l'application (fenêtres, dossiers) ; un seul mot, sans espace
PRODUIT = "Turini Assistance"


# Réception seule : le client affiche son ID et son code, ne prend jamais la main sur un autre poste,
# ne s'installe pas et n'a aucun réglage visible ; le serveur et sa clé sont fixés à la compilation.
REGLAGES = {
    "HARD_SETTINGS": {
        "conn-type": "incoming",
        "disable-settings": "Y",
        "disable-installation": "Y",
        "disable-ab": "Y",
        "disable-account": "Y",
    },
    "BUILTIN_SETTINGS": {
        "hide-help-cards": "Y",
        "hide-powered-by-me": "Y",
        "hide-general-settings": "Y",
        "hide-security-settings": "Y",
        "hide-network-settings": "Y",
        "hide-server-settings": "Y",
        "hide-proxy-settings": "Y",
        "hide-websocket-settings": "Y",
        "hide-remote-printer-settings": "Y",
        "hide-stop-service": "Y",
        "disable-change-id": "Y",
        "disable-change-permanent-password": "Y",
    },
    # Imposés même si un fichier de configuration local dit autre chose.
    "OVERWRITE_SETTINGS": {
        "verification-method": "use-temporary-password",  # code à usage unique, jamais de mot de passe permanent
        "allow-remote-config-modification": "N",  # le technicien ne peut pas changer ces réglages à distance
        "enable-lan-discovery": "N",  # le poste ne s'annonce pas sur le réseau local
        "direct-server": "N",  # pas d'accès direct par adresse IP, tout passe par le serveur Turini
    },
    "OVERWRITE_LOCAL_SETTINGS": {
        "theme": "light",
    },
}


POLICES = [  # polices du site (SIL Open Font License, textes dans turini/marque/polices/)
    ("Barlow", "Barlow-Regular.ttf", 400),
    ("Barlow", "Barlow-SemiBold.ttf", 600),
    ("BarlowCondensed", "BarlowCondensed-ExtraBoldItalic.ttf", 800),
    ("JetBrainsMono", "JetBrainsMono-Medium.ttf", 500),
]


def polices_pubspec():
    lignes = []
    for famille in dict.fromkeys(f for f, _, _ in POLICES):
        lignes += [f"    - family: {famille}", "      fonts:"]
        for _, fichier, poids in (p for p in POLICES if p[0] == famille):
            lignes += [f"        - asset: assets/{fichier}", f"          weight: {poids}"]
            if "Italic" in fichier:
                lignes.append("          style: italic")
    return "\n".join(lignes) + "\n"


def table_rust(valeurs):
    paires = ", ".join(f'("{k}", "{v}")' for k, v in valeurs.items())
    return f"[{paires}].iter().map(|(k, v)| (k.to_string(), v.to_string())).collect()"


def remplacer(fichier, ancien, nouveau):
    chemin = RACINE / fichier
    texte = chemin.read_text(encoding="utf-8")
    nombre = texte.count(ancien)
    if nombre != 1:
        sys.exit(f"{fichier} : « {ancien} » trouvé {nombre} fois au lieu d'une : RustDesk a changé, adapter ce script.")
    chemin.write_text(texte.replace(ancien, nouveau), encoding="utf-8")
    print(f"{fichier} : modifié")


def remplacer_ligne(fichier, motif, nouveau):
    """Comme remplacer, pour une ligne dont une partie change d'une version à l'autre (l'année)."""
    chemin = RACINE / fichier
    texte, nombre = re.subn(motif, lambda _: nouveau, chemin.read_text(encoding="utf-8"), flags=re.M)
    if nombre != 1:
        sys.exit(f"{fichier} : « {motif} » trouvé {nombre} fois au lieu d'une : RustDesk a changé, adapter ce script.")
    chemin.write_text(texte, encoding="utf-8")
    print(f"{fichier} : modifié")


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    hote, cle = sys.argv[1].strip(), sys.argv[2].strip()
    if not re.fullmatch(r"[A-Za-z0-9.-]+", hote):
        sys.exit(f"Adresse de serveur invalide : {hote!r}")
    if not re.fullmatch(r"[A-Za-z0-9+/]{43}=", cle):
        sys.exit("Clé publique invalide : 44 caractères attendus (contenu de id_ed25519.pub).")

    config = "libs/hbb_common/src/config.rs"
    remplacer(config, 'pub const RENDEZVOUS_SERVERS: &[&str] = &["rs-ny.rustdesk.com"];',
              f'pub const RENDEZVOUS_SERVERS: &[&str] = &["{hote}"];')
    remplacer(config, 'pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";',
              f'pub const RS_PUB_KEY: &str = "{cle}";')
    # Un nom différent de « RustDesk » fait de l'application un client personnalisé : pas de
    # vérification de mise à jour chez RustDesk, et « RustDesk » remplacé par ce nom dans les textes.
    remplacer(config, 'pub static ref APP_NAME: RwLock<String> = RwLock::new("RustDesk".to_owned());',
              f'pub static ref APP_NAME: RwLock<String> = RwLock::new("{NOM}".to_owned());')
    remplacer(config, 'pub static ref ORG: RwLock<String> = RwLock::new("com.carriez".to_owned());',
              'pub static ref ORG: RwLock<String> = RwLock::new("fr.turini".to_owned());')

    # Réglages verrouillés à la compilation. RustDesk ne les accepte d'ordinaire que dans une
    # configuration signée par sa société (custom.txt) : on remplit directement ses tables.
    for table, valeurs in REGLAGES.items():
        remplacer(config, f"pub static ref {table}: RwLock<HashMap<String, String>> = Default::default();",
                  f"pub static ref {table}: RwLock<HashMap<String, String>> = RwLock::new({table_rust(valeurs)});")

    couleurs = "flutter/lib/common.dart"
    for nom, alpha in (("accent", "FF"), ("accent50", "77"), ("accent80", "AA")):
        remplacer(couleurs, f"static const Color {nom} = Color(0x{alpha}0071FF);",
                  f"static const Color {nom} = Color(0x{alpha}12357A);")

    # Écran d'accueil Turini (turini/flutter/) à la place de celui de RustDesk en réception seule.
    accueil = "flutter/lib/desktop/pages/desktop_home_page.dart"
    remplacer(accueil, "import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';\n",
              "import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';\n"
              "import 'package:flutter_hbb/desktop/pages/turini_accueil.dart';\n")
    remplacer(accueil, "    super.build(context);\n    final isIncomingOnly = bind.isIncomingOnly();\n",
              "    super.build(context);\n    final isIncomingOnly = bind.isIncomingOnly();\n"
              "    if (isIncomingOnly) return _buildBlock(child: const TuriniAccueil());\n")
    remplacer("flutter/pubspec.yaml", "  fonts:\n    - family: GestureIcons\n",
              "  fonts:\n" + polices_pubspec() + "    - family: GestureIcons\n")

    # Sans serveur d'API à nous, ne jamais se rabattre sur celui de RustDesk (comptes, appareils).
    remplacer("src/common.rs", '    "https://admin.rustdesk.com".to_owned()\n}',
              "    String::new()\n}")

    rc = "flutter/windows/runner/Runner.rc"
    remplacer(rc, 'VALUE "CompanyName", "Purslane Tech Pte. Ltd." "\\0"', 'VALUE "CompanyName", "Turini" "\\0"')
    remplacer(rc, 'VALUE "FileDescription", "RustDesk Remote Desktop" "\\0"',
              f'VALUE "FileDescription", "{PRODUIT}" "\\0"')
    remplacer(rc, 'VALUE "ProductName", "RustDesk" "\\0"', f'VALUE "ProductName", "{PRODUIT}" "\\0"')
    remplacer(rc, 'All rights reserved." "\\0"',
              'Turini, d\'après RustDesk (AGPL-3.0, code : github.com/Alpine56/turini-assistance)." "\\0"')

    # Lanceur portable : raccourci sur le bureau et mise à jour au démarrage
    # (src/turini_bureau.rs et src/turini_maj.rs, propres à Turini).
    portable = "libs/portable"
    remplacer(f"{portable}/src/main.rs", "fn main() -> Result<(), String> {",
              "#[cfg(windows)]\nmod turini_bureau;\n#[cfg(windows)]\nmod turini_maj;\n\nfn main() -> Result<(), String> {")
    remplacer(f"{portable}/src/main.rs", "    let click_setup = args.is_empty()",
              "    #[cfg(windows)]\n    if args.is_empty() && (turini_bureau::preparer() || turini_maj::verifier()) {\n"
              "        return Ok(());\n    }\n"
              "    let click_setup = args.is_empty()")
    remplacer(f"{portable}/Cargo.toml", '    "Win32_System_SystemInformation",\n] }',
              '    "Win32_System_SystemInformation",\n    "Win32_Security",\n    "Win32_Security_Cryptography",\n'
              '    "Win32_System_Com",\n    "Win32_System_Com_Urlmon",\n    "Win32_UI",\n'
              '    "Win32_UI_WindowsAndMessaging",\n    "Win32_UI_Shell",\n] }')
    remplacer(f"{portable}/Cargo.toml", 'ProductName = "RustDesk"', f'ProductName = "{PRODUIT}"')
    remplacer(f"{portable}/Cargo.toml", 'FileDescription = "RustDesk Remote Desktop"', f'FileDescription = "{PRODUIT}"')
    remplacer(f"{portable}/Cargo.toml", 'OriginalFilename = "rustdesk.exe"', 'OriginalFilename = "turini-assistance.exe"')
    remplacer_ligne(f"{portable}/Cargo.toml", r'^LegalCopyright = "Copyright © \d{4} Purslane Tech Pte\. Ltd\. All rights reserved\."$',
                    'LegalCopyright = "Turini, d\'après RustDesk (AGPL-3.0, code : github.com/Alpine56/turini-assistance)"')

    copies = {
        "icon.ico": ["res/icon.ico", "flutter/windows/runner/resources/app_icon.ico"],
        "icon.png": ["res/icon.png"],
        "32x32.png": ["res/32x32.png"],
        "64x64.png": ["res/64x64.png"],
        "128x128.png": ["res/128x128.png"],
        "128x128@2x.png": ["res/128x128@2x.png"],
        "mac-icon.png": ["res/mac-icon.png"],
        "icon.svg": ["flutter/assets/icon.svg", "res/logo.svg", "res/scalable.svg"],
    }
    for source, cibles in copies.items():
        for cible in cibles:
            if not (RACINE / cible).exists():
                sys.exit(f"{cible} n'existe plus : RustDesk a changé, adapter ce script.")
            shutil.copyfile(MARQUE / source, RACINE / cible)
    if not (RACINE / "libs/portable/src/ui.rs").exists():
        sys.exit("libs/portable/src/ui.rs n'existe plus : RustDesk a changé, adapter ce script.")
    nouveaux = {
        MARQUE / "logo-entete.svg": "flutter/assets/turini-logo.svg",
        MARQUE / "logo-mot.svg": "flutter/assets/turini-mot.svg",
        # Fenêtre de préparation du lanceur : la voiture Turini au lieu de « Loading... ».
        RACINE / "turini" / "lanceur" / "ui.rs": "libs/portable/src/ui.rs",
        RACINE / "turini" / "lanceur" / "demarrage.gif": "libs/portable/src/res/turini-demarrage.gif",
    }
    nouveaux.update({MARQUE / "polices" / f: f"flutter/assets/{f}" for _, f, _ in POLICES})
    nouveaux.update({f: f"flutter/lib/desktop/pages/{f.name}" for f in (RACINE / "turini" / "flutter").glob("*.dart")})
    for source, cible in nouveaux.items():
        shutil.copyfile(source, RACINE / cible)
    print(f"Icônes Turini copiées. Client {PRODUIT} : serveur {hote}.")


if __name__ == "__main__":
    main()
