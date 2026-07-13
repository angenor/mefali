# Contrat — trait `ServiceWorkflow` (crate `commandes`)

Cadrage §11.11 : le tronc commande est générique ; chaque vertical fournit sa
table de détails et son implémentation de ce trait (états intermédiaires,
validations, hooks de tarification). **Ce cycle définit le trait, sans aucune
implémentation** (constitution IX — prêt ≠ construit).

## Signature provisoire (stabilisée au cycle CMD)

```rust
/// États de très haut niveau du tronc commande — les SEULS que le crate
/// `commandes` connaît (cadrage §11.11). Aucun champ logistique.
pub enum EtatCommande { Creee, EnCours, Terminee, Annulee, Litige }

/// Implémenté par chaque vertical (resto_courses au MVP ; pressing,
/// intervention… ensuite). Le vertical possède sa table de détails
/// (`resto_details`…) et ses états intermédiaires.
#[async_trait]
pub trait ServiceWorkflow: Send + Sync {
    /// Identifiant du vertical (ex. "resto_courses").
    fn vertical(&self) -> &'static str;

    /// États intermédiaires du vertical, projetés sur EtatCommande.
    fn etats_intermediaires(&self) -> &'static [EtatIntermediaire];

    /// Valide une transition d'état intermédiaire (le serveur fait foi).
    async fn valider_transition(
        &self,
        de: &str,
        vers: &str,
        ctx: &ContexteWorkflow,
    ) -> Result<(), WorkflowError>;

    /// Hook de tarification du vertical (appelé par le crate tarification).
    async fn ajustements_tarification(
        &self,
        ctx: &ContexteWorkflow,
    ) -> Result<Vec<AjustementTarif>, WorkflowError>;
}

pub struct EtatIntermediaire {
    pub code: &'static str,          // clé i18n dérivée, jamais de libellé en dur
    pub etat_tronc: EtatCommande,    // projection sur le tronc
}
```

`ContexteWorkflow`, `AjustementTarif` (montants : entiers unités mineures +
ISO 4217, constitution III) et `WorkflowError` sont des types du crate
`commandes`, squelettes ce cycle.

## Règles de conception verrouillées

- Aucun crate partagé ne suppose « commande = livraison » ni
  « prestataire = vendeur » (constitution II) — le trait n'expose RIEN de
  logistique ; la livraison est un composant optionnel rattaché ailleurs.
- Le dispatch filtre sur des CAPACITÉS requises — le trait n'introduit aucune
  notion de véhicule.
- Compilation garantie : le crate `commandes` compile avec ce trait et zéro
  implémentation.
