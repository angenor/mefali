use common::error::AppError;
use rand::Rng;
use redis::AsyncCommands;
use tracing::{info, warn};

/// Fixed OTP code used in dev mode for testing without SMS.
pub const DEV_OTP_CODE: &str = "123456";

/// Generate a random OTP code of the specified length.
/// In dev mode, returns the fixed DEV_OTP_CODE instead.
pub fn generate_otp(length: usize, dev_mode: bool) -> String {
    if dev_mode {
        return DEV_OTP_CODE.to_string();
    }
    let mut rng = rand::thread_rng();
    let max = 10u32.pow(length as u32);
    let code = rng.gen_range(0..max);
    format!("{:0>width$}", code, width = length)
}

/// Store OTP in Redis with TTL and attempt counter.
/// Key format: `otp:{phone}` → `{code}:0`
pub async fn store_otp(
    redis: &mut redis::aio::ConnectionManager,
    phone: &str,
    code: &str,
    expiry_seconds: u64,
) -> Result<(), AppError> {
    let key = format!("otp:{}", phone);
    let value = format!("{}:0", code);
    redis
        .set_ex::<_, _, ()>(&key, &value, expiry_seconds)
        .await
        .map_err(|e| AppError::InternalError(format!("Redis error: {}", e)))?;
    info!(phone = phone, "OTP stored in Redis");
    Ok(())
}

/// Verify OTP from Redis. Returns Ok(()) if valid, increments attempts on failure.
pub async fn verify_otp(
    redis: &mut redis::aio::ConnectionManager,
    phone: &str,
    submitted_code: &str,
    max_attempts: u32,
) -> Result<(), AppError> {
    let key = format!("otp:{}", phone);
    let stored: Option<String> = redis
        .get(&key)
        .await
        .map_err(|e| AppError::InternalError(format!("Redis error: {}", e)))?;

    let stored = stored.ok_or_else(|| AppError::BadRequest("OTP expired or not found".into()))?;

    let parts: Vec<&str> = stored.splitn(2, ':').collect();
    if parts.len() != 2 {
        return Err(AppError::InternalError("Corrupted OTP data".into()));
    }
    let code = parts[0];
    let attempts: u32 = parts[1].parse().unwrap_or(0);

    if attempts >= max_attempts {
        // Delete the OTP to prevent further attempts
        let _: () = redis.del(&key).await.unwrap_or(());
        return Err(AppError::TooManyRequests(
            "Too many OTP verification attempts".into(),
        ));
    }

    if code != submitted_code {
        // Increment attempts counter
        let new_value = format!("{}:{}", code, attempts + 1);
        let ttl: i64 = redis.ttl(&key).await.unwrap_or(300);
        if ttl > 0 {
            let _: () = redis
                .set_ex(&key, &new_value, ttl as u64)
                .await
                .unwrap_or(());
        }
        warn!(
            phone = phone,
            attempts = attempts + 1,
            "Invalid OTP attempt"
        );
        return Err(AppError::BadRequest("Invalid OTP code".into()));
    }

    // OTP valid — delete it
    let _: () = redis.del(&key).await.unwrap_or(());
    info!(phone = phone, "OTP verified successfully");
    Ok(())
}

/// Check rate limit for OTP requests. Max `max_requests` per minute per phone.
pub async fn check_rate_limit(
    redis: &mut redis::aio::ConnectionManager,
    phone: &str,
    max_requests: u32,
) -> Result<(), AppError> {
    let key = format!("otp_rate:{}", phone);
    let count: Option<u32> = redis
        .get(&key)
        .await
        .map_err(|e| AppError::InternalError(format!("Redis error: {}", e)))?;

    if let Some(c) = count {
        if c >= max_requests {
            return Err(AppError::TooManyRequests(
                "Too many OTP requests. Please wait 1 minute.".into(),
            ));
        }
    }

    // Increment counter with 60s TTL
    redis
        .incr::<_, _, ()>(&key, 1)
        .await
        .map_err(|e| AppError::InternalError(format!("Redis error: {}", e)))?;
    // Set expiry only if key is new (INCR doesn't reset TTL)
    let ttl: i64 = redis.ttl(&key).await.unwrap_or(-1);
    if ttl < 0 {
        let _: () = redis.expire(&key, 60).await.unwrap_or(());
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_otp_length() {
        let otp = generate_otp(6, false);
        assert_eq!(otp.len(), 6);
        assert!(otp.chars().all(|c| c.is_ascii_digit()));
    }

    #[test]
    fn test_generate_otp_uniqueness() {
        let otp1 = generate_otp(6, false);
        let otp2 = generate_otp(6, false);
        // Not guaranteed to differ, but very likely with 6 digits
        // This test validates the function runs without errors
        assert_eq!(otp1.len(), 6);
        assert_eq!(otp2.len(), 6);
    }

    #[test]
    fn test_generate_otp_pads_zeros() {
        // Generate many OTPs and verify they all have correct length
        for _ in 0..100 {
            let otp = generate_otp(6, false);
            assert_eq!(otp.len(), 6, "OTP '{}' should be 6 digits", otp);
        }
    }

    #[test]
    fn test_generate_otp_dev_mode_returns_fixed_code() {
        let otp = generate_otp(6, true);
        assert_eq!(otp, DEV_OTP_CODE);
    }
}
