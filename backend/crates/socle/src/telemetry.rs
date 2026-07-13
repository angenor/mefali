//! Observabilité (TRX-03) : logs JSON structurés corrélés (tracing) + Sentry.
//!
//! La corrélation par requête (request id) est ajoutée côté `api` par
//! `tracing-actix-web` ; Sentry capture les erreurs HTTP via `sentry-actix`.
//! Ici : initialisation du subscriber et du client Sentry.

use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::EnvFilter;

/// Garde de télémétrie : conserve vivant le client Sentry pour toute la durée
/// du process (les événements ne sont envoyés que tant que le garde vit).
#[must_use = "à conserver vivant pour toute la durée du process"]
pub struct TelemetryGuard {
    _sentry: Option<sentry::ClientInitGuard>,
}

/// Initialise Sentry si un DSN non vide est fourni (désactivé sinon — dev).
fn init_sentry(dsn: Option<&str>) -> Option<sentry::ClientInitGuard> {
    dsn.filter(|d| !d.is_empty()).map(|dsn| {
        sentry::init((
            dsn.to_owned(),
            sentry::ClientOptions {
                release: sentry::release_name!(),
                ..Default::default()
            },
        ))
    })
}

/// Initialise la télémétrie : logs JSON sur stdout (filtre `RUST_LOG`, défaut
/// `info`) et Sentry si `SENTRY_DSN` est renseigné. Renvoie un garde à garder
/// vivant (typiquement dans `main`).
pub fn init_telemetry(sentry_dsn: Option<&str>) -> TelemetryGuard {
    // Sentry initialisé avant le subscriber (les breadcrumbs peuvent en dépendre).
    let sentry_guard = init_sentry(sentry_dsn);

    let filtre = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info"));

    tracing_subscriber::registry()
        .with(filtre)
        .with(tracing_subscriber::fmt::layer().json())
        .init();

    TelemetryGuard {
        _sentry: sentry_guard,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sentry_desactive_sans_dsn() {
        assert!(init_sentry(None).is_none());
        assert!(init_sentry(Some("")).is_none());
    }
}
