use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

/// Create a PostgreSQL connection pool from a database URL.
pub async fn create_pool(database_url: &str) -> Result<PgPool, sqlx::Error> {
    PgPoolOptions::new()
        .max_connections(10)
        .connect(database_url)
        .await
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_database_module_compiles() {
        // Validates that the database module compiles correctly
        // Integration tests with a real DB will be in Story 1.4
        assert!(true);
    }
}
