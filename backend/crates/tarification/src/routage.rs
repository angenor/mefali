//! Client de routage OSRM `/table`, cache par tronçon et **mode dégradé**
//! (US2 — T014/T015/T016, research R2/R3, constitution IV).
//!
//! Trois couches empilées, volontairement séparées :
//!
//! 1. [`Routage`] — transport brut. [`RoutageOsrm`] interroge **une seule fois**
//!    `/table` pour toute la course (R2) ; [`RoutageIndisponible`] est son
//!    contraire, pour les tests et pour un déploiement sans OSRM.
//! 2. [`matrice_cachee`] — lit d'abord le cache par **tronçon** ; n'appelle le
//!    transport que si une paire manque (R3). C'est cette séparation qui rend
//!    SC-004 démontrable : un double compteur d'appels reste à 1 au 2ᵉ passage.
//! 3. [`matrice_ou_degrade`] — **jamais d'échec** : si le transport tombe, la
//!    matrice est reconstruite en vol d'oiseau × facteur de zone, `degraded`
//!    posé. Une commande n'est jamais bloquée par le routage (constitution IV).

use async_trait::async_trait;
use serde::Deserialize;

use crate::modele::{ErreurRoutage, Matrice, Point};
use crate::ports::{CacheRoutage, Routage};

/// Délai au-delà duquel OSRM est considéré indisponible.
///
/// Paramètre TECHNIQUE (pas métier) : il ne vit donc pas en configuration de
/// zone. Court volontairement — mieux vaut un devis dégradé tracé en 2 s qu'un
/// client qui attend 30 s un itinéraire exact (objectif « devis perçu
/// instantané », plan « Performance Goals »).
pub const OSRM_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(2);

/// Rayon terrestre moyen (mètres) — repli vol d'oiseau.
const RAYON_TERRE_M: f64 = 6_371_000.0;

/// Routage TOUJOURS indisponible.
///
/// Double de test du mode dégradé (quickstart, SC-003) **et** repli de
/// composition tant qu'aucun serveur OSRM n'est configuré : le service tarife
/// alors en vol d'oiseau × facteur de zone, `degraded=true` journalisé — il ne
/// refuse jamais de tarifer (constitution IV).
#[derive(Debug, Default, Clone, Copy)]
pub struct RoutageIndisponible;

#[async_trait]
impl Routage for RoutageIndisponible {
    async fn matrice(&self, _points: &[Point]) -> Result<Matrice, ErreurRoutage> {
        Err(ErreurRoutage::Indisponible(
            "aucun service de routage configuré".to_owned(),
        ))
    }
}

// ── T014 : client OSRM `/table` ────────────────────────────────────────────

/// Réponse du service `/table` d'OSRM (champs consommés seulement).
#[derive(Debug, Deserialize)]
struct ReponseTable {
    code: String,
    /// `n × n` mètres. `null` = paire non joignable.
    distances: Option<Vec<Vec<Option<f64>>>>,
    /// `n × n` secondes.
    durations: Option<Vec<Vec<Option<f64>>>>,
}

/// Client OSRM : **une** requête `/table` par course, pas une par permutation.
///
/// `/table` rend tous les tronçons d'un coup ; optimiser l'ordre par `/route`
/// coûterait jusqu'à 4! = 24 allers-retours (research R2). La matrice sert aussi
/// à classer la « distance au précédent arrêt » du barème d'effort (FR-029),
/// sans second appel.
#[derive(Debug, Clone)]
pub struct RoutageOsrm {
    client: reqwest::Client,
    base_url: String,
}

impl RoutageOsrm {
    /// Construit le client sur l'URL du service (`OSRM_URL`).
    pub fn nouveau(base_url: &str) -> Result<Self, ErreurRoutage> {
        let client = reqwest::Client::builder()
            .timeout(OSRM_TIMEOUT)
            .build()
            .map_err(|e| ErreurRoutage::Indisponible(format!("client HTTP : {e}")))?;
        Ok(Self {
            client,
            base_url: base_url.trim_end_matches('/').to_owned(),
        })
    }

    /// URL `/table` pour ces points. ⚠ OSRM attend **`lon,lat`**, dans cet
    /// ordre — l'inverse de nos types, et une inversion silencieuse enverrait
    /// les courses de Tiassalé au milieu de l'Atlantique.
    fn url(&self, points: &[Point]) -> String {
        let coords = points
            .iter()
            .map(|p| format!("{:.6},{:.6}", p.lon, p.lat))
            .collect::<Vec<_>>()
            .join(";");
        format!(
            "{}/table/v1/driving/{coords}?annotations=distance,duration",
            self.base_url
        )
    }
}

#[async_trait]
impl Routage for RoutageOsrm {
    async fn matrice(&self, points: &[Point]) -> Result<Matrice, ErreurRoutage> {
        let n = points.len();
        if n == 0 {
            return Err(ErreurRoutage::ReponseInvalide("aucun point".to_owned()));
        }
        let reponse = self
            .client
            .get(self.url(points))
            .send()
            .await
            .map_err(|e| ErreurRoutage::Indisponible(e.to_string()))?;
        if !reponse.status().is_success() {
            return Err(ErreurRoutage::Indisponible(format!(
                "OSRM a répondu {}",
                reponse.status()
            )));
        }
        let corps: ReponseTable = reponse
            .json()
            .await
            .map_err(|e| ErreurRoutage::ReponseInvalide(e.to_string()))?;
        if corps.code != "Ok" {
            return Err(ErreurRoutage::ReponseInvalide(format!(
                "code OSRM « {} »",
                corps.code
            )));
        }
        let (Some(distances), Some(durations)) = (corps.distances, corps.durations) else {
            return Err(ErreurRoutage::ReponseInvalide(
                "annotations distance/duration absentes".to_owned(),
            ));
        };

        // Un `null` = paire non joignable par la route. On ne « bouche » pas le
        // trou en douce : la matrice entière est déclarée invalide, l'appelant
        // bascule en dégradé TRACÉ. Mieux vaut un devis marqué approximatif
        // qu'un devis exact en apparence, faux sur un tronçon.
        let mut plates_distances = Vec::with_capacity(n * n);
        let mut plates_durees = Vec::with_capacity(n * n);
        for (ligne_d, ligne_t) in distances.iter().zip(durations.iter()) {
            if ligne_d.len() != n || ligne_t.len() != n {
                return Err(ErreurRoutage::ReponseInvalide(format!(
                    "matrice {n}×{n} attendue"
                )));
            }
            for (d, t) in ligne_d.iter().zip(ligne_t.iter()) {
                let (Some(d), Some(t)) = (d, t) else {
                    return Err(ErreurRoutage::ReponseInvalide(
                        "paire de points non joignable par la route".to_owned(),
                    ));
                };
                plates_distances.push(d.round() as i64);
                plates_durees.push(t.round() as i64);
            }
        }
        if plates_distances.len() != n * n {
            return Err(ErreurRoutage::ReponseInvalide(format!(
                "matrice {n}×{n} attendue, reçu {} lignes",
                distances.len()
            )));
        }
        Matrice::nouvelle(n, plates_distances, plates_durees, false)
    }
}

// ── T015 : cache par tronçon ───────────────────────────────────────────────

/// Options de cache résolues **depuis la zone** (constitution I).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct OptionsCache {
    /// Durée de vie d'un tronçon caché (secondes) — `routage.cache_ttl_h`.
    pub ttl_s: u64,
    /// Décimales de l'arrondi des coordonnées dans la clé —
    /// `routage.arrondi_cle_decimales` (4 ≈ 11 m, research R3).
    pub decimales: u32,
}

/// Clé d'un tronçon : `tarif:route:v1:{lat_a},{lon_a}:{lat_b},{lon_b}`.
///
/// Coordonnées **arrondies** : deux départs distants de quelques mètres
/// partagent le même tronçon, ce qui est tout l'intérêt d'un cache par paire
/// (R3). La clé est ORIENTÉE (a→b ≠ b→a) : un sens unique rend les deux sens
/// différents, les confondre fausserait la distance.
pub fn cle_troncon(de: Point, vers: Point, decimales: u32) -> String {
    let d = decimales as usize;
    format!(
        "tarif:route:v1:{:.*},{:.*}:{:.*},{:.*}",
        d, de.lat, d, de.lon, d, vers.lat, d, vers.lon
    )
}

/// Matrice servie par le **cache** quand tous les tronçons y sont, sinon par le
/// transport — qui alimente alors le cache.
///
/// Tout-ou-rien volontaire : `/table` rend la matrice complète en une requête,
/// demander à OSRM un sous-ensemble de paires coûterait autant que la totalité.
/// La promesse de SC-004 est donc « une course déjà routée ne rappelle pas le
/// routage », pas « chaque tronçon connu économise un octet ».
///
/// Une panne du cache n'est **jamais** fatale : elle se journalise et coûte un
/// appel de routage (éphémère reconstructible, constitution II).
pub async fn matrice_cachee(
    routage: &dyn Routage,
    cache: &dyn CacheRoutage,
    points: &[Point],
    options: OptionsCache,
) -> Result<Matrice, ErreurRoutage> {
    let n = points.len();
    if n == 0 {
        return Err(ErreurRoutage::ReponseInvalide("aucun point".to_owned()));
    }

    // Clés de toutes les paires ORIENTÉES hors diagonale, en ordre ligne-majeur.
    let mut cles = Vec::with_capacity(n * n - n);
    for de in 0..n {
        for vers in 0..n {
            if de != vers {
                cles.push(cle_troncon(points[de], points[vers], options.decimales));
            }
        }
    }

    let lus = match cache.lire(&cles).await {
        Ok(lus) if lus.len() == cles.len() => lus,
        Ok(_) => {
            tracing::warn!("cache de routage : réponse de taille inattendue — ignorée");
            vec![None; cles.len()]
        }
        Err(e) => {
            tracing::warn!(erreur = %e, "cache de routage illisible — appel de routage");
            vec![None; cles.len()]
        }
    };

    if lus.iter().all(Option::is_some) {
        let mut distances = vec![0i64; n * n];
        let mut durees = vec![0i64; n * n];
        let mut k = 0;
        for de in 0..n {
            for vers in 0..n {
                if de == vers {
                    continue;
                }
                let t = lus[k].expect("tronçon présent — vérifié juste au-dessus");
                distances[de * n + vers] = t.distance_m;
                durees[de * n + vers] = t.duree_s;
                k += 1;
            }
        }
        return Matrice::nouvelle(n, distances, durees, false);
    }

    let matrice = routage.matrice(points).await?;
    if matrice.taille() != n {
        return Err(ErreurRoutage::ReponseInvalide(format!(
            "matrice de {} points pour {n} demandés",
            matrice.taille()
        )));
    }
    let mut entrees = Vec::with_capacity(cles.len());
    let mut k = 0;
    for de in 0..n {
        for vers in 0..n {
            if de != vers {
                entrees.push((cles[k].clone(), matrice.troncon(de, vers)));
                k += 1;
            }
        }
    }
    if let Err(e) = cache.ecrire(&entrees, options.ttl_s).await {
        tracing::warn!(erreur = %e, "cache de routage non alimenté — sans conséquence");
    }
    Ok(matrice)
}

// ── T016 : mode dégradé (constitution IV) ──────────────────────────────────

/// Distance orthodromique (« vol d'oiseau ») en mètres.
///
/// Réimplémentée ici plutôt qu'empruntée à `qr` : la proximité point-rayon du
/// scan est un contrôle ANTI-FRAUDE distinct (plan, Constitution IV) et lier
/// les deux modules coupleraient la tarification à la logistique de collecte.
pub fn distance_grand_cercle_m(a: Point, b: Point) -> f64 {
    let (lat1, lat2) = (a.lat.to_radians(), b.lat.to_radians());
    let dlat = lat2 - lat1;
    let dlon = (b.lon - a.lon).to_radians();
    let h = (dlat / 2.0).sin().powi(2) + lat1.cos() * lat2.cos() * (dlon / 2.0).sin().powi(2);
    2.0 * RAYON_TERRE_M * h.sqrt().asin()
}

/// Matrice de repli : vol d'oiseau × facteur de zone, `degraded = true`.
///
/// Le facteur (1,4 par défaut à Tiassalé) approche la sinuosité du réseau :
/// une route fait rarement la ligne droite. La durée est estimée à la vitesse
/// de repli de la zone — l'ETA reste une estimation honnête plutôt qu'un zéro
/// trompeur.
pub fn matrice_degradee(points: &[Point], facteur: f64, vitesse_kmh: f64) -> Matrice {
    let n = points.len();
    let vitesse_ms = (vitesse_kmh.max(1.0) * 1000.0) / 3600.0;
    let mut distances = vec![0i64; n * n];
    let mut durees = vec![0i64; n * n];
    for de in 0..n {
        for vers in 0..n {
            if de == vers {
                continue;
            }
            let m = distance_grand_cercle_m(points[de], points[vers]) * facteur;
            distances[de * n + vers] = m.round() as i64;
            durees[de * n + vers] = (m / vitesse_ms).round() as i64;
        }
    }
    Matrice::nouvelle(n, distances, durees, true).expect("matrice dégradée bien dimensionnée")
}

/// Matrice de la course — **jamais d'erreur de routage** (constitution IV).
///
/// Cache → transport → repli. Le seul échec possible est une demande vide, que
/// l'appelant a déjà écartée. Le drapeau `degraded` de la matrice remonte
/// jusqu'au devis et déclenche l'événement `routage.degrade` (T019).
pub async fn matrice_ou_degrade(
    routage: &dyn Routage,
    cache: &dyn CacheRoutage,
    points: &[Point],
    options: OptionsCache,
    facteur_degrade: f64,
    vitesse_degradee_kmh: f64,
) -> Matrice {
    match matrice_cachee(routage, cache, points, options).await {
        Ok(matrice) => matrice,
        Err(e) => {
            tracing::warn!(
                erreur = %e, nb_points = points.len(), facteur = facteur_degrade,
                "routage indisponible — devis en DÉGRADÉ vol d'oiseau (jamais bloquant)",
            );
            matrice_degradee(points, facteur_degrade, vitesse_degradee_kmh)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ports::CacheMemoire;
    use std::sync::atomic::{AtomicUsize, Ordering};

    fn p(lat: f64, lon: f64) -> Point {
        Point { lat, lon }
    }

    /// Routage déterministe qui COMPTE ses appels (double de SC-004).
    struct RoutageCompteur {
        appels: AtomicUsize,
    }

    #[async_trait]
    impl Routage for RoutageCompteur {
        async fn matrice(&self, points: &[Point]) -> Result<Matrice, ErreurRoutage> {
            self.appels.fetch_add(1, Ordering::SeqCst);
            let n = points.len();
            let mut d = vec![0i64; n * n];
            let mut t = vec![0i64; n * n];
            for de in 0..n {
                for vers in 0..n {
                    if de != vers {
                        d[de * n + vers] = ((de + 1) * 100 + (vers + 1)) as i64;
                        t[de * n + vers] = d[de * n + vers] / 5;
                    }
                }
            }
            Matrice::nouvelle(n, d, t, false)
        }
    }

    const OPTIONS: OptionsCache = OptionsCache {
        ttl_s: 86_400,
        decimales: 4,
    };

    /// SC-004 — la 2ᵉ évaluation de la même course ne rappelle PAS le routage.
    #[tokio::test]
    async fn cache_evite_le_second_appel() {
        let routage = RoutageCompteur {
            appels: AtomicUsize::new(0),
        };
        let cache = CacheMemoire::nouveau();
        let points = [p(5.898, -4.823), p(5.900, -4.820), p(5.902, -4.818)];

        let un = matrice_cachee(&routage, &cache, &points, OPTIONS)
            .await
            .unwrap();
        assert_eq!(routage.appels.load(Ordering::SeqCst), 1);
        assert_eq!(cache.taille(), 3 * 3 - 3, "toutes les paires orientées");

        let deux = matrice_cachee(&routage, &cache, &points, OPTIONS)
            .await
            .unwrap();
        assert_eq!(
            routage.appels.load(Ordering::SeqCst),
            1,
            "2ᵉ passage servi par le cache"
        );
        assert_eq!(un, deux, "et à l'identique");

        // TTL écoulé (cache vidé) → on rappelle le routage.
        cache.vider();
        matrice_cachee(&routage, &cache, &points, OPTIONS)
            .await
            .unwrap();
        assert_eq!(routage.appels.load(Ordering::SeqCst), 2);
    }

    /// Une clé de cache est ORIENTÉE et arrondie à la précision de zone.
    #[test]
    fn cle_orientee_et_arrondie() {
        let (a, b) = (p(5.8981234, -4.8234567), p(5.9002, -4.8201));
        assert_ne!(cle_troncon(a, b, 4), cle_troncon(b, a, 4), "sens unique");
        // 5.8981234 et 5.8981 tombent sur la même clé à 4 décimales (~11 m).
        assert_eq!(
            cle_troncon(a, b, 4),
            cle_troncon(p(5.8981, -4.8234567), b, 4)
        );
        assert_ne!(
            cle_troncon(a, b, 6),
            cle_troncon(p(5.8981, -4.8234567), b, 6),
            "à 6 décimales, les deux points se distinguent"
        );
    }

    /// SC-003 — routage indisponible : la matrice sort quand même, marquée.
    #[tokio::test]
    async fn degrade_ne_bloque_jamais() {
        let points = [p(5.898, -4.823), p(5.908, -4.823)];
        let matrice = matrice_ou_degrade(
            &RoutageIndisponible,
            &CacheMemoire::nouveau(),
            &points,
            OPTIONS,
            1.4,
            20.0,
        )
        .await;
        assert!(matrice.degraded, "devis marqué approximatif");

        // 0,01° de latitude ≈ 1 111 m ; ×1,4 ≈ 1 556 m.
        let d = matrice.troncon(0, 1).distance_m;
        assert!(
            (1_540..=1_570).contains(&d),
            "vol d'oiseau × 1,4 attendu, obtenu {d} m"
        );
        assert!(matrice.troncon(0, 1).duree_s > 0, "ETA estimée, pas zéro");
        assert_eq!(matrice.troncon(0, 0).distance_m, 0, "diagonale nulle");
    }

    /// Le facteur de dégradé vient de la ZONE : le changer change la distance.
    #[test]
    fn facteur_degrade_parametrable() {
        let points = [p(5.898, -4.823), p(5.908, -4.823)];
        let brut = matrice_degradee(&points, 1.0, 20.0).troncon(0, 1).distance_m;
        let majore = matrice_degradee(&points, 1.4, 20.0).troncon(0, 1).distance_m;
        assert_eq!(majore, (brut as f64 * 1.4).round() as i64);
    }

    /// L'URL OSRM sort les coordonnées en **lon,lat** — l'inverse de nos types.
    #[test]
    fn url_osrm_en_lon_lat() {
        let client = RoutageOsrm::nouveau("http://osrm:5000/").unwrap();
        let url = client.url(&[p(5.898, -4.823), p(5.900, -4.820)]);
        assert_eq!(
            url,
            "http://osrm:5000/table/v1/driving/-4.823000,5.898000;-4.820000,5.900000\
             ?annotations=distance,duration"
        );
    }
}
