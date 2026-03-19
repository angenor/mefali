use common::types::{Id, Timestamp};
use serde::Serialize;

/// Count of items across three time periods: today, this week, and total.
#[derive(Debug, Clone, Serialize)]
pub struct PeriodCount {
    pub today: i64,
    pub this_week: i64,
    pub total: i64,
}

/// Count of merchants with first order (no "today" — orders trickle in).
#[derive(Debug, Clone, Serialize)]
pub struct FirstOrderCount {
    pub this_week: i64,
    pub total: i64,
}

/// A recently onboarded merchant shown on the agent dashboard.
#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct RecentMerchant {
    pub id: Id,
    pub name: String,
    pub created_at: Timestamp,
    pub has_first_order: bool,
}

/// Complete agent performance stats returned by the API.
#[derive(Debug, Clone, Serialize)]
pub struct AgentPerformanceStats {
    pub merchants_onboarded: PeriodCount,
    pub kyc_validated: PeriodCount,
    pub merchants_with_first_order: FirstOrderCount,
    pub recent_merchants: Vec<RecentMerchant>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_period_count_serde() {
        let pc = PeriodCount {
            today: 4,
            this_week: 12,
            total: 47,
        };
        let json = serde_json::to_value(&pc).unwrap();
        assert_eq!(json["today"], 4);
        assert_eq!(json["this_week"], 12);
        assert_eq!(json["total"], 47);
    }

    #[test]
    fn test_first_order_count_serde() {
        let fc = FirstOrderCount {
            this_week: 2,
            total: 35,
        };
        let json = serde_json::to_value(&fc).unwrap();
        assert_eq!(json["this_week"], 2);
        assert_eq!(json["total"], 35);
    }

    #[test]
    fn test_agent_performance_stats_serde() {
        let stats = AgentPerformanceStats {
            merchants_onboarded: PeriodCount {
                today: 3,
                this_week: 10,
                total: 50,
            },
            kyc_validated: PeriodCount {
                today: 1,
                this_week: 4,
                total: 20,
            },
            merchants_with_first_order: FirstOrderCount {
                this_week: 2,
                total: 40,
            },
            recent_merchants: vec![],
        };
        let json = serde_json::to_value(&stats).unwrap();
        assert_eq!(json["merchants_onboarded"]["today"], 3);
        assert_eq!(json["kyc_validated"]["total"], 20);
        assert_eq!(json["merchants_with_first_order"]["this_week"], 2);
        assert!(json["recent_merchants"].as_array().unwrap().is_empty());
    }
}
