//! US7 (cycle PAY 011, T077) — `refund` est **définie, jamais appelée**
//! (FR-041, FR-111).
//!
//! # Pourquoi la définir puisqu'on ne l'appelle pas
//!
//! Parce que PAY-05 promet un fournisseur **interchangeable**, et qu'un
//! remboursement fait partie de ce qu'un fournisseur de paiement sait faire. Un
//! trait qui l'omettrait obligerait à le rouvrir — donc à retoucher toutes les
//! implémentations — le jour où PAY-04 sera construit. C'est exactement la
//! bascule que ce cycle existe pour rendre indolore.
//!
//! # Pourquoi ne PAS l'appeler
//!
//! PAY-04 est hors périmètre (FR-041). L'appeler ici construirait la story
//! qu'on a explicitement exclue — et le remboursement automatique d'un paiement
//! hors délai est précisément l'alternative que research R8 a rejetée. Ce que
//! le produit fait à la place : il **ouvre un dossier**, et l'exploitation
//! décide (FR-082).
//!
//! # Ce que ce test mesure vraiment
//!
//! Une vérification **mécanique** sur les sources : aucun fichier du produit —
//! hors du module fournisseur qui la définit, et hors tests — ne contient
//! d'appel à `refund`. Un test qui se contenterait de « je n'ai pas écrit
//! d'appel » ne prouverait rien pour le prochain qui passe ; celui-ci échoue le
//! jour où quelqu'un en ajoute un, y compris par inadvertance dans un chemin
//! d'erreur.
//!
//! C'est le même patron que `scripts/verifier-frontiere-paiement.sh` : une
//! règle qu'on se contente d'affirmer se franchit au premier correctif pressé.

use std::path::{Path, PathBuf};

/// Racine du workspace backend, déduite de l'emplacement de ce crate.
fn racine_backend() -> PathBuf {
    // `CARGO_MANIFEST_DIR` = backend/crates/paiements
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .and_then(Path::parent)
        .expect("le crate vit sous backend/crates/")
        .to_path_buf()
}

/// Tous les fichiers `.rs` sous un répertoire, récursivement.
fn sources_rust(racine: &Path, trouves: &mut Vec<PathBuf>) {
    let Ok(entrees) = std::fs::read_dir(racine) else {
        return;
    };
    for entree in entrees.flatten() {
        let chemin = entree.path();
        if chemin.is_dir() {
            // `target/` contient les sources des dépendances : les scanner
            // ferait échouer le test sur le code de quelqu'un d'autre.
            if chemin.file_name().is_some_and(|n| n == "target") {
                continue;
            }
            sources_rust(&chemin, trouves);
        } else if chemin.extension().is_some_and(|e| e == "rs") {
            trouves.push(chemin);
        }
    }
}

/// FR-041, FR-111 — **aucun chemin de code du produit n'invoque `refund`**.
#[test]
fn aucun_chemin_du_produit_n_invoque_refund() {
    let racine = racine_backend();
    let mut fichiers = Vec::new();
    sources_rust(&racine, &mut fichiers);
    assert!(
        fichiers.len() > 50,
        "le balayage n'a trouvé que {} fichiers — il ne scanne visiblement pas \
         le workspace, et un test qui ne regarde rien passe toujours",
        fichiers.len(),
    );

    let mut coupables = Vec::new();
    for fichier in &fichiers {
        let relatif = fichier.strip_prefix(&racine).unwrap_or(fichier);
        let chemin = relatif.to_string_lossy().replace('\\', "/");

        // Exempté : le module fournisseur, qui la DÉFINIT (trait, client HTTP,
        // doubles), et les tests, dont celui-ci.
        if chemin.starts_with("crates/paiements/src/fournisseur/")
            || chemin.contains("/tests/")
            || chemin.starts_with("tests/")
        {
            continue;
        }

        let Ok(contenu) = std::fs::read_to_string(fichier) else {
            continue;
        };
        for (numero, ligne) in contenu.lines().enumerate() {
            let sans_commentaire = ligne.split("//").next().unwrap_or("");
            // Un APPEL, pas une mention : `.refund(` ou `refund(`. La
            // documentation du trait en parle abondamment, et interdire le mot
            // rendrait le code inexplicable.
            if sans_commentaire.contains(".refund(") || sans_commentaire.contains("refund(&") {
                coupables.push(format!("{chemin}:{}", numero + 1));
            }
        }
    }

    assert!(
        coupables.is_empty(),
        "`refund` est appelée par le produit, ce que FR-041 interdit : {}\n\
         \n\
         PAY-04 est hors périmètre de ce cycle. Ce que le produit fait d'un\n\
         paiement à rendre, c'est OUVRIR UN DOSSIER (FR-082) — l'exploitation\n\
         décide, et le remboursement automatique reste l'alternative que\n\
         research R8 a rejetée.",
        coupables.join(", "),
    );
}

/// La méthode existe bien dans le trait — sans quoi le test précédent
/// passerait pour une raison stupide.
#[test]
fn refund_est_bien_definie_sur_le_trait() {
    let trait_source = std::fs::read_to_string(
        racine_backend().join("crates/paiements/src/fournisseur/mod.rs"),
    )
    .expect("le module fournisseur est lisible");

    assert!(
        trait_source.contains("async fn refund("),
        "`refund` doit rester définie : l'omettre obligerait à rouvrir le trait \
         — et donc toutes ses implémentations — le jour où PAY-04 arrive, ce \
         qui est exactement la bascule que PAY-05 rend indolore",
    );
}

/// Les deux implémentations livrées la fournissent : un fournisseur qui ne
/// compilerait pas le jour de la bascule ne serait pas interchangeable.
#[test]
fn les_deux_implementations_la_fournissent() {
    let racine = racine_backend();
    for (fichier, quoi) in [
        ("crates/paiements/src/fournisseur/simule.rs", "le double"),
        (
            "crates/paiements/src/fournisseur/agregateur.rs",
            "le client HTTP",
        ),
    ] {
        let source = std::fs::read_to_string(racine.join(fichier)).unwrap();
        assert!(
            source.contains("fn refund("),
            "{quoi} doit implémenter `refund`",
        );
    }
}
