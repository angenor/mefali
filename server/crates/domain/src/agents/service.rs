use common::error::AppError;
use common::types::Id;
use sqlx::PgPool;
use tracing::info;

use chrono::{Datelike, Duration, NaiveTime, Utc};

use super::model::{AgentPerformanceStats, FirstOrderCount, PeriodCount};
use super::repository;

/// Get comprehensive performance stats for the authenticated agent.
/// Calculates today, this week (Monday→Sunday), and all-time counts.
pub async fn get_agent_performance_stats(
    pool: &PgPool,
    agent_user_id: Id,
) -> Result<AgentPerformanceStats, AppError> {
    // Calculate time boundaries
    let now = Utc::now();
    let today = now.date_naive();
    let days_from_monday = today.weekday().num_days_from_monday() as i64;
    let current_monday = today - Duration::days(days_from_monday);
    let next_monday = current_monday + Duration::days(7);
    let tomorrow = today + Duration::days(1);

    let to_ts = |d: chrono::NaiveDate| d.and_time(NaiveTime::MIN).and_utc();

    let today_start = to_ts(today);
    let today_end = to_ts(tomorrow);
    let week_start = to_ts(current_monday);
    let week_end = to_ts(next_monday);

    // Fetch all counts in parallel via tokio::try_join!
    let (
        merchants_today,
        merchants_week,
        merchants_total,
        kyc_today,
        kyc_week,
        kyc_total,
        first_order_week,
        first_order_total,
        recent_merchants,
    ) = tokio::try_join!(
        repository::count_merchants_onboarded(pool, agent_user_id, today_start, today_end),
        repository::count_merchants_onboarded(pool, agent_user_id, week_start, week_end),
        repository::count_merchants_onboarded_total(pool, agent_user_id),
        repository::count_kyc_validated(pool, agent_user_id, today_start, today_end),
        repository::count_kyc_validated(pool, agent_user_id, week_start, week_end),
        repository::count_kyc_validated_total(pool, agent_user_id),
        repository::count_merchants_with_first_order(pool, agent_user_id, week_start, week_end),
        repository::count_merchants_with_first_order_total(pool, agent_user_id),
        repository::find_recent_onboarded(pool, agent_user_id, 5),
    )?;

    info!(
        agent_id = agent_user_id.to_string(),
        merchants_today = merchants_today,
        merchants_week = merchants_week,
        merchants_total = merchants_total,
        "Agent performance stats fetched"
    );

    Ok(AgentPerformanceStats {
        merchants_onboarded: PeriodCount {
            today: merchants_today,
            this_week: merchants_week,
            total: merchants_total,
        },
        kyc_validated: PeriodCount {
            today: kyc_today,
            this_week: kyc_week,
            total: kyc_total,
        },
        merchants_with_first_order: FirstOrderCount {
            this_week: first_order_week,
            total: first_order_total,
        },
        recent_merchants,
    })
}

#[cfg(test)]
mod tests {
    use chrono::{Datelike, Duration, NaiveTime, Utc};

    /// Verify week boundary calculation logic (same as in service).
    #[test]
    fn test_week_boundaries() {
        let today = Utc::now().date_naive();
        let days_from_monday = today.weekday().num_days_from_monday() as i64;
        let current_monday = today - Duration::days(days_from_monday);
        let next_monday = current_monday + Duration::days(7);

        // Monday is always a Monday
        assert_eq!(
            current_monday.weekday(),
            chrono::Weekday::Mon,
            "current_monday must be Monday"
        );
        // next_monday is 7 days later
        assert_eq!((next_monday - current_monday).num_days(), 7);
        // today falls within [current_monday, next_monday)
        assert!(today >= current_monday);
        assert!(today < next_monday);
    }

    /// Verify today boundaries are correct.
    #[test]
    fn test_today_boundaries() {
        let today = Utc::now().date_naive();
        let tomorrow = today + Duration::days(1);

        let to_ts = |d: chrono::NaiveDate| d.and_time(NaiveTime::MIN).and_utc();

        let today_start = to_ts(today);
        let today_end = to_ts(tomorrow);

        // Today start is midnight
        assert_eq!(today_start.time(), NaiveTime::MIN);
        // Difference is exactly 1 day
        assert_eq!((today_end - today_start).num_hours(), 24);
    }
}
