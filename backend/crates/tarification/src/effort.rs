//! Grille d'effort : paliers d'articles, prime d'attente (une fois par course),
//! supplément d'arrêt sur tronçon routier (US6 — T029, FR-028/FR-029).
//!
//! Les trois composantes sont **100 % reversées à la part coursier** : la marge
//! Mefali est strictement inchangée par l'effort (SC-007). Le calcul lui-même
//! est greffé au pipeline en US6 ; ce type est la valeur qui circule.

/// Détail de la grille d'effort, en unités mineures. **Intégralement** part
/// coursier.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Effort {
    /// Palier d'articles de la commande (FR-028, composante 1).
    pub paliers: i64,
    /// Prime d'attente — **une seule fois par course** (FR-028, composante 2 ;
    /// clarification du 2026-07-24).
    pub attente: i64,
    /// Suppléments d'arrêt, indexés sur le tronçon routier au précédent
    /// (FR-028/FR-029, composante 3).
    pub arrets: i64,
}

impl Effort {
    /// Total des trois composantes.
    pub fn total(&self) -> i64 {
        self.paliers + self.attente + self.arrets
    }
}
