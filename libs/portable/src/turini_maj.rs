//! Turini Assistance : mise à jour au démarrage (Windows).
//!
//! Au lancement par double clic, le lanceur lit le fichier de version publié sur le site de
//! Turini (TURINI_URL_MAJ, fixé à la compilation), trois lignes :
//!     version=2026.10.18.1
//!     url=https://…/turini-assistance.exe
//!     sha256=<empreinte hexadécimale de l'exécutable>
//! Si la version est plus récente que la sienne (TURINI_VERSION), il propose la mise à jour.
//! Sur accord : téléchargement à côté de l'exécutable, vérification de l'empreinte, échange des
//! fichiers (Windows permet de renommer un exécutable en cours d'utilisation), redémarrage.
//! Au moindre problème (pas de réseau, dossier en lecture seule, empreinte fausse), le logiciel
//! démarre simplement dans sa version actuelle.

use std::{
    path::{Path, PathBuf},
    process::Command,
};
use windows::{
    core::HSTRING,
    Win32::{
        Security::Cryptography::{BCryptHash, BCRYPT_SHA256_ALG_HANDLE},
        System::Com::Urlmon::URLDownloadToFileW,
        UI::WindowsAndMessaging::{
            MessageBoxW, IDYES, MB_ICONINFORMATION, MB_ICONWARNING, MB_OK, MB_YESNO,
        },
    },
};

const VERSION: Option<&str> = option_env!("TURINI_VERSION");
const URL_MAJ: Option<&str> = option_env!("TURINI_URL_MAJ");
const TITRE: &str = "Turini Assistance";

/// Renvoie vrai si la nouvelle version vient d'être lancée : l'appelant doit alors s'arrêter.
pub fn verifier() -> bool {
    let (Some(version), Some(url_maj)) = (VERSION, URL_MAJ) else {
        return false;
    };
    let Ok(exe) = std::env::current_exe() else {
        return false;
    };
    let ancien = suffixe(&exe, ".ancien");
    let nouveau = suffixe(&exe, ".nouveau");
    std::fs::remove_file(&ancien).ok();
    std::fs::remove_file(&nouveau).ok();

    let fiche = std::env::temp_dir().join("turini-assistance-version.txt");
    let horodatage = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or_default();
    // Paramètre unique : évite que Windows serve une ancienne fiche depuis son cache.
    if !telecharger(&format!("{url_maj}?t={horodatage}"), &fiche) {
        return false;
    }
    let texte = std::fs::read_to_string(&fiche).unwrap_or_default();
    std::fs::remove_file(&fiche).ok();
    let (Some(distante), Some(url), Some(empreinte)) =
        (valeur(&texte, "version"), valeur(&texte, "url"), valeur(&texte, "sha256"))
    else {
        return false;
    };
    if !plus_recente(&distante, version) {
        return false;
    }
    let question = format!(
        "Une nouvelle version de Turini Assistance est disponible ({distante}).\n\nL'installer maintenant ? Le logiciel redémarrera tout seul."
    );
    if boite(&question, MB_YESNO | MB_ICONINFORMATION) != IDYES.0 {
        return false;
    }
    if !telecharger(&url, &nouveau) || !empreinte_valide(&nouveau, &empreinte) {
        std::fs::remove_file(&nouveau).ok();
        boite(
            "La mise à jour n'a pas pu être téléchargée correctement.\nTurini Assistance démarre dans sa version actuelle.",
            MB_OK | MB_ICONWARNING,
        );
        return false;
    }
    if std::fs::rename(&exe, &ancien).is_err() {
        std::fs::remove_file(&nouveau).ok();
        return false;
    }
    if std::fs::rename(&nouveau, &exe).is_err() {
        std::fs::rename(&ancien, &exe).ok();
        return false;
    }
    Command::new(&exe).spawn().is_ok()
}

fn suffixe(chemin: &Path, ajout: &str) -> PathBuf {
    let mut nom = chemin.as_os_str().to_owned();
    nom.push(ajout);
    PathBuf::from(nom)
}

fn telecharger(url: &str, cible: &Path) -> bool {
    unsafe { URLDownloadToFileW(None, &HSTRING::from(url), &HSTRING::from(cible.as_os_str()), 0, None) }
        .is_ok()
}

fn valeur(texte: &str, cle: &str) -> Option<String> {
    texte.lines().find_map(|ligne| {
        let (k, v) = ligne.split_once('=')?;
        (k.trim() == cle && !v.trim().is_empty()).then(|| v.trim().to_owned())
    })
}

fn numeros(version: &str) -> Vec<u64> {
    version.split('.').map(|n| n.trim().parse().unwrap_or(0)).collect()
}

fn plus_recente(distante: &str, locale: &str) -> bool {
    numeros(distante) > numeros(locale)
}

fn empreinte_valide(fichier: &Path, attendue: &str) -> bool {
    let Ok(contenu) = std::fs::read(fichier) else {
        return false;
    };
    let mut sortie = [0u8; 32];
    let statut = unsafe { BCryptHash(BCRYPT_SHA256_ALG_HANDLE, None, &contenu, &mut sortie) };
    if statut.is_err() {
        return false;
    }
    let calculee: String = sortie.iter().map(|o| format!("{o:02x}")).collect();
    calculee.eq_ignore_ascii_case(attendue.trim())
}

fn boite(texte: &str, style: windows::Win32::UI::WindowsAndMessaging::MESSAGEBOX_STYLE) -> i32 {
    unsafe { MessageBoxW(None, &HSTRING::from(texte), &HSTRING::from(TITRE), style) }.0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn compare_les_versions_numero_par_numero() {
        assert!(plus_recente("2026.10.18.2", "2026.10.18.1"));
        assert!(plus_recente("2026.11.1.1", "2026.10.18.9"));
        assert!(!plus_recente("2026.10.18.1", "2026.10.18.1"));
        assert!(!plus_recente("2026.9.30.5", "2026.10.1.1"));
    }

    #[test]
    fn lit_la_fiche_de_version() {
        let fiche = "version=2026.10.18.2\nurl=https://exemple/turini-assistance.exe\nsha256=ABC\n";
        assert_eq!(valeur(fiche, "version").as_deref(), Some("2026.10.18.2"));
        assert_eq!(valeur(fiche, "sha256").as_deref(), Some("ABC"));
        assert_eq!(valeur(fiche, "absent"), None);
    }
}
