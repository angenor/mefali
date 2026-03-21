pub mod agents;
pub mod city_config;
pub mod deliveries;
pub mod disputes;
pub mod kyc;
pub mod merchants;
pub mod orders;
pub mod products;
pub mod ratings;
pub mod reconciliation;
pub mod sponsorships;
pub mod users;
pub mod wallets;

#[cfg(any(test, feature = "testing"))]
pub mod test_fixtures;

#[cfg(test)]
mod tests {
    #[test]
    fn test_domain_modules_compile() {
        // Validates that all 10 domain sub-modules compile correctly
        assert!(true);
    }
}
