use serde::Deserialize;

/// Re-export UUID v4 for consistent usage across crates
pub type Id = uuid::Uuid;

/// Re-export DateTime<Utc> for consistent timestamp usage
pub type Timestamp = chrono::DateTime<chrono::Utc>;

/// Pagination query parameters
#[derive(Debug, Clone, Deserialize)]
pub struct PaginationParams {
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_per_page")]
    pub per_page: i64,
}

fn default_page() -> i64 {
    1
}

fn default_per_page() -> i64 {
    20
}

impl Default for PaginationParams {
    fn default() -> Self {
        Self {
            page: default_page(),
            per_page: default_per_page(),
        }
    }
}

impl PaginationParams {
    pub fn offset(&self) -> i64 {
        (self.page - 1) * self.per_page
    }
}

/// Generate a new UUID v4
pub fn new_id() -> Id {
    uuid::Uuid::new_v4()
}

/// Get current UTC timestamp
pub fn now() -> Timestamp {
    chrono::Utc::now()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pagination_defaults() {
        let params = PaginationParams::default();
        assert_eq!(params.page, 1);
        assert_eq!(params.per_page, 20);
    }

    #[test]
    fn test_pagination_offset() {
        let params = PaginationParams {
            page: 3,
            per_page: 10,
        };
        assert_eq!(params.offset(), 20);
    }

    #[test]
    fn test_new_id_is_unique() {
        let id1 = new_id();
        let id2 = new_id();
        assert_ne!(id1, id2);
    }
}
