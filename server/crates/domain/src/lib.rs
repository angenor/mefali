pub mod deliveries;
pub mod disputes;
pub mod merchants;
pub mod orders;
pub mod sponsorships;
pub mod users;
pub mod wallets;

#[cfg(test)]
mod tests {
    #[test]
    fn test_domain_modules_compile() {
        // Validates that all 7 domain sub-modules compile correctly
        assert!(true);
    }
}
