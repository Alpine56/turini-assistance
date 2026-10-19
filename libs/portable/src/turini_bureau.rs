//! Turini Assistance : raccourci sur le bureau (Windows).
//!
//! Au premier lancement, le logiciel se recopie dans le dossier de l'utilisateur
//! (%LOCALAPPDATA%\Turini\Assistance) et pose un raccourci « Turini Assistance » à son logo sur le
//! bureau. Rien n'est installé : ni service, ni droits administrateur, ni entrée dans le registre.
//! Le client retrouve ainsi le logiciel d'un double clic, et les mises à jour s'appliquent à cette
//! copie. Au moindre problème, le logiciel démarre simplement depuis l'endroit où il a été lancé.

use std::{
    path::{Path, PathBuf},
    process::Command,
};
use windows::{
    core::{Interface, HSTRING},
    Win32::{
        System::Com::{
            CoCreateInstance, CoInitializeEx, IPersistFile, CLSCTX_INPROC_SERVER,
            COINIT_APARTMENTTHREADED,
        },
        UI::Shell::{IShellLinkW, ShellLink},
    },
};

const NOM: &str = "Turini Assistance";

/// Renvoie vrai si la copie du dossier utilisateur vient d'être lancée : l'appelant doit s'arrêter.
pub fn preparer() -> bool {
    let (Ok(exe), Some(dossier)) = (std::env::current_exe(), dirs::data_local_dir()) else {
        return false;
    };
    let cible = dossier.join("Turini").join("Assistance").join(format!("{NOM}.exe"));
    if meme_fichier(&exe, &cible) {
        poser_raccourci(&cible);
        return false;
    }
    if recopier(&exe, &cible).is_err() {
        return false;
    }
    poser_raccourci(&cible);
    Command::new(&cible).spawn().is_ok()
}

fn meme_fichier(a: &Path, b: &Path) -> bool {
    match (a.canonicalize(), b.canonicalize()) {
        (Ok(a), Ok(b)) => a.as_os_str().eq_ignore_ascii_case(b.as_os_str()),
        _ => false,
    }
}

/// Une copie en cours d'utilisation est renommée (Windows le permet) puis supprimée au démarrage
/// suivant par turini_maj.
fn recopier(source: &Path, cible: &Path) -> std::io::Result<()> {
    if let Some(dossier) = cible.parent() {
        std::fs::create_dir_all(dossier)?;
    }
    let nouveau = suffixe(cible, ".nouveau");
    std::fs::copy(source, &nouveau)?;
    if cible.exists() {
        let ancien = suffixe(cible, ".ancien");
        std::fs::remove_file(&ancien).ok();
        std::fs::rename(cible, &ancien)?;
    }
    std::fs::rename(&nouveau, cible)
}

fn suffixe(chemin: &Path, ajout: &str) -> PathBuf {
    let mut nom = chemin.as_os_str().to_owned();
    nom.push(ajout);
    PathBuf::from(nom)
}

fn poser_raccourci(cible: &Path) {
    let Some(bureau) = dirs::desktop_dir() else {
        return;
    };
    let raccourci = bureau.join(format!("{NOM}.lnk"));
    if raccourci.exists() {
        return;
    }
    let _ = creer_lien(cible, &raccourci);
}

fn creer_lien(cible: &Path, raccourci: &Path) -> windows::core::Result<()> {
    unsafe {
        let _ = CoInitializeEx(None, COINIT_APARTMENTTHREADED);
        let lien: IShellLinkW = CoCreateInstance(&ShellLink, None, CLSCTX_INPROC_SERVER)?;
        lien.SetPath(&HSTRING::from(cible.as_os_str()))?;
        if let Some(dossier) = cible.parent() {
            lien.SetWorkingDirectory(&HSTRING::from(dossier.as_os_str()))?;
        }
        lien.SetDescription(&HSTRING::from("Assistance à distance Turini"))?;
        lien.SetIconLocation(&HSTRING::from(cible.as_os_str()), 0)?;
        let fichier: IPersistFile = lien.cast()?;
        fichier.Save(&HSTRING::from(raccourci.as_os_str()), true)
    }
}
