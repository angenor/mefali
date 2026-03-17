pub mod upload;

use aws_config::BehaviorVersion;
use aws_sdk_s3::config::{Credentials, Region};
use aws_sdk_s3::Client;

/// Create an S3-compatible client configured for MinIO.
pub async fn create_s3_client(endpoint: &str, access_key: &str, secret_key: &str) -> Client {
    let credentials = Credentials::new(access_key, secret_key, None, None, "mefali");

    let config = aws_sdk_s3::Config::builder()
        .behavior_version(BehaviorVersion::latest())
        .region(Region::new("us-east-1"))
        .endpoint_url(endpoint)
        .credentials_provider(credentials)
        .force_path_style(true)
        .build();

    Client::from_conf(config)
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_storage_module_compiles() {
        // Validates that the storage module compiles correctly
        // Integration tests with MinIO will be in later stories
        assert!(true);
    }
}
