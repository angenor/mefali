//! Composition du PDF de plaque imprimable (QRC-01, research R2).
//!
//! Le PDF est un artefact d'IMPRESSION : aucune contrainte de tokens, aucune
//! maquette (US1 est sans UI). La matrice QR (`qrcode`, correction M) est
//! dessinée en **rectangles vectoriels** (`printpdf`) — net à toute échelle,
//! sans dépendance raster. Le jeton existe déjà (cycle 005) : on le consomme.

use printpdf::{
    BuiltinFont, Color, Mm, Op, PaintMode, PdfDocument, PdfFontHandle, PdfPage, PdfSaveOptions,
    Point, Pt, Rect, Rgb, TextItem,
};
use qrcode::{Color as ModuleQr, QrCode};
use uuid::Uuid;

/// Domaine produit encodé dans le QR (`mefali.com`, harmonisé docs 2026-07-22).
/// L'URL complète respecte FR-009 : `{domaine}/v/{prestataire_id}?t={jeton}` —
/// le prestataire est dans le CHEMIN, le jeton dans le paramètre `t` (le scan
/// et le futur cycle WEB en dépendent).
const DOMAINE_PLAQUE: &str = "https://mefali.com";

/// Titre imprimé (texte rendu SERVEUR — clé i18n `plaque.titre`). Seul texte
/// utilisateur rendu côté serveur : artefact d'impression, sans locale client à
/// négocier. Le reste (nom, code) est de la donnée, pas de l'i18n.
const TITRE_PLAQUE: &str = "Vendeur agréé Mefali";
/// Libellé du code de secours (clé i18n `plaque.code_secours`).
const LIBELLE_CODE: &str = "Code de secours";

// Géométrie A6 portrait (mm).
const PAGE_L_MM: f32 = 105.0;
const PAGE_H_MM: f32 = 148.0;
const QR_COTE_MM: f32 = 60.0;
const QR_BAS_MM: f32 = 60.0; // bord inférieur du carré QR

/// Compose le PDF de plaque : titre + QR (URL FR-009) + nom + code de secours.
/// Retourne les octets du PDF (commence par `%PDF`).
pub fn composer_plaque_pdf(
    prestataire_id: Uuid,
    nom: &str,
    jeton: &str,
    code_secours: &str,
) -> Vec<u8> {
    let mut ops = Vec::new();

    // Tout en noir (impression).
    ops.push(Op::SetFillColor {
        col: Color::Rgb(Rgb::new(0.0, 0.0, 0.0, None)),
    });

    // ── Titre (centré, en haut) ────────────────────────────────────────────
    pousser_texte_centre(&mut ops, TITRE_PLAQUE, 16.0, 130.0);

    // ── QR dessiné en modules vectoriels ───────────────────────────────────
    // FR-009 : `{domaine}/v/{prestataire_id}?t={jeton}`.
    let url = format!("{DOMAINE_PLAQUE}/v/{prestataire_id}?t={jeton}");
    let code = QrCode::new(url.as_bytes()).expect("jeton court — encodage QR toujours possible");
    let modules = code.width(); // matrice carrée `modules × modules`
    let pas_mm = QR_COTE_MM / modules as f32;
    let gauche_mm = (PAGE_L_MM - QR_COTE_MM) / 2.0;
    let matrice = code.to_colors(); // Dark = module sombre, ligne par ligne (haut→bas)
    for (i, module) in matrice.iter().enumerate() {
        if *module != ModuleQr::Dark {
            continue;
        }
        let col = i % modules;
        let ligne = i / modules;
        // Origine PDF en bas à gauche : on inverse la ligne (QR compté du haut).
        let x = gauche_mm + col as f32 * pas_mm;
        let y = QR_BAS_MM + (modules - 1 - ligne) as f32 * pas_mm;
        ops.push(Op::DrawRectangle {
            rectangle: Rect {
                x: mm(x),
                y: mm(y),
                // Léger surdimensionnement (+2 %) pour souder les modules à
                // l'impression et éviter les liserés blancs entre carrés.
                width: mm(pas_mm * 1.02),
                height: mm(pas_mm * 1.02),
                mode: Some(PaintMode::Fill),
                winding_order: None,
            },
        });
    }

    // ── Nom du prestataire (centré, sous le QR) ─────────────────────────────
    pousser_texte_centre(&mut ops, nom, 14.0, 46.0);

    // ── Code de secours (libellé + code en gros) ────────────────────────────
    pousser_texte_centre(&mut ops, LIBELLE_CODE, 11.0, 30.0);
    pousser_texte_centre(&mut ops, code_secours, 28.0, 14.0);

    let page = PdfPage::new(Mm(PAGE_L_MM), Mm(PAGE_H_MM), ops);
    let mut doc = PdfDocument::new("Plaque Mefali");
    doc.with_pages(vec![page]);
    let mut avertissements = Vec::new();
    doc.save(&PdfSaveOptions::default(), &mut avertissements)
}

/// Convertit des millimètres en points PDF.
fn mm(v: f32) -> Pt {
    Mm(v).into()
}

/// Pousse un texte approximativement centré horizontalement à l'ordonnée `y_mm`.
/// Largeur estimée à ~0,5 em par caractère (suffisant pour un artefact d'impression).
fn pousser_texte_centre(ops: &mut Vec<Op>, texte: &str, taille_pt: f32, y_mm: f32) {
    let largeur_pt = texte.chars().count() as f32 * taille_pt * 0.5;
    let largeur_mm = largeur_pt / 2.834_646; // pt → mm
    let x_mm = ((PAGE_L_MM - largeur_mm) / 2.0).max(4.0);
    let gras = matches!(taille_pt as i32, 14 | 16 | 28);
    ops.push(Op::StartTextSection);
    ops.push(Op::SetFont {
        font: PdfFontHandle::Builtin(if gras {
            BuiltinFont::HelveticaBold
        } else {
            BuiltinFont::Helvetica
        }),
        size: Pt(taille_pt),
    });
    ops.push(Op::SetTextCursor {
        pos: Point::new(Mm(x_mm), Mm(y_mm)),
    });
    ops.push(Op::ShowText {
        items: vec![TextItem::Text(texte.to_owned())],
    });
    ops.push(Op::EndTextSection);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn produit_un_pdf_valide() {
        let pdf = composer_plaque_pdf(Uuid::now_v7(), "Tantie Affoué", &"a".repeat(80), "0421");
        assert!(pdf.starts_with(b"%PDF"), "en-tête PDF présent");
        assert!(pdf.len() > 500, "le PDF porte du contenu (QR + textes)");
    }

    #[test]
    fn regeneration_meme_entete() {
        // Le jeton est stable (SC-001) : deux compositions du même contenu
        // produisent au moins le même en-tête PDF.
        let id = Uuid::now_v7();
        let a = composer_plaque_pdf(id, "Kofi", &"b".repeat(80), "1234");
        let b = composer_plaque_pdf(id, "Kofi", &"b".repeat(80), "1234");
        assert!(a.starts_with(b"%PDF") && b.starts_with(b"%PDF"));
    }
}
