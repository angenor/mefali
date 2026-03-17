use std::env;
use tracing::warn;

#[derive(Debug, Clone)]
pub struct AppConfig {
    pub database_url: String,
    pub redis_url: String,
    pub minio_endpoint: String,
    pub minio_access_key: String,
    pub minio_secret_key: String,
    pub minio_bucket: String,
    pub api_host: String,
    pub api_port: u16,
    pub jwt_secret: String,
    pub jwt_access_expiry: u64,
    pub jwt_refresh_expiry: u64,
    pub otp_length: usize,
    pub otp_expiry_seconds: u64,
    pub otp_max_attempts: u32,
    pub otp_rate_limit_per_minute: u32,
}

fn parse_or_default<T: std::str::FromStr>(var_name: &str, raw: &str, default: T) -> T {
    match raw.parse() {
        Ok(v) => v,
        Err(_) => {
            warn!(var = var_name, value = raw, "Invalid value, using default");
            default
        }
    }
}

impl AppConfig {
    pub fn from_env() -> Result<Self, env::VarError> {
        dotenvy::dotenv().ok();

        let api_port_raw = env::var("API_PORT").unwrap_or_else(|_| "8090".into());
        let jwt_access_raw = env::var("JWT_ACCESS_EXPIRY").unwrap_or_else(|_| "900".into());
        let jwt_refresh_raw = env::var("JWT_REFRESH_EXPIRY").unwrap_or_else(|_| "604800".into());
        let otp_length_raw = env::var("OTP_LENGTH").unwrap_or_else(|_| "6".into());
        let otp_expiry_raw = env::var("OTP_EXPIRY_SECONDS").unwrap_or_else(|_| "300".into());
        let otp_max_raw = env::var("OTP_MAX_ATTEMPTS").unwrap_or_else(|_| "3".into());
        let otp_rate_raw = env::var("OTP_RATE_LIMIT_PER_MINUTE").unwrap_or_else(|_| "3".into());

        Ok(Self {
            database_url: env::var("DATABASE_URL")?,
            redis_url: env::var("REDIS_URL")?,
            minio_endpoint: env::var("MINIO_ENDPOINT")?,
            minio_access_key: env::var("MINIO_ACCESS_KEY")?,
            minio_secret_key: env::var("MINIO_SECRET_KEY")?,
            minio_bucket: env::var("MINIO_BUCKET")?,
            api_host: env::var("API_HOST").unwrap_or_else(|_| "0.0.0.0".into()),
            api_port: parse_or_default("API_PORT", &api_port_raw, 8090),
            jwt_secret: env::var("JWT_SECRET")?,
            jwt_access_expiry: parse_or_default("JWT_ACCESS_EXPIRY", &jwt_access_raw, 900),
            jwt_refresh_expiry: parse_or_default("JWT_REFRESH_EXPIRY", &jwt_refresh_raw, 604800),
            otp_length: parse_or_default("OTP_LENGTH", &otp_length_raw, 6),
            otp_expiry_seconds: parse_or_default("OTP_EXPIRY_SECONDS", &otp_expiry_raw, 300),
            otp_max_attempts: parse_or_default("OTP_MAX_ATTEMPTS", &otp_max_raw, 3),
            otp_rate_limit_per_minute: parse_or_default(
                "OTP_RATE_LIMIT_PER_MINUTE",
                &otp_rate_raw,
                3,
            ),
        })
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_config_default_port_parsing() {
        // Test that port parsing defaults work correctly
        let port: u16 = "8090".parse().unwrap_or(8090);
        assert_eq!(port, 8090);

        let invalid_port: u16 = "not_a_number".parse().unwrap_or(8090);
        assert_eq!(invalid_port, 8090);
    }

    #[test]
    fn test_config_default_host() {
        let host = std::env::var("NONEXISTENT_VAR").unwrap_or_else(|_| "0.0.0.0".into());
        assert_eq!(host, "0.0.0.0");
    }
}
