use redis::aio::ConnectionManager;
use redis::Client;

/// Create a Redis connection manager from a URL.
pub async fn create_connection(redis_url: &str) -> Result<ConnectionManager, redis::RedisError> {
    let client = Client::open(redis_url)?;
    ConnectionManager::new(client).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_redis_client_creation() {
        // Validates that a Redis client can be created from a URL
        let client = Client::open("redis://localhost:6380");
        assert!(client.is_ok());
    }
}
