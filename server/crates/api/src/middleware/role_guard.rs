use common::error::AppError;
use domain::users::model::UserRole;

use crate::extractors::AuthenticatedUser;

/// Verify that the authenticated user has one of the required roles.
/// Returns 403 Forbidden if the user's role is not in the allowed list.
pub fn require_role(user: &AuthenticatedUser, roles: &[UserRole]) -> Result<(), AppError> {
    if roles.contains(&user.role) {
        Ok(())
    } else {
        Err(AppError::Forbidden(
            "Insufficient permissions for this resource".into(),
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    fn make_user(role: UserRole) -> AuthenticatedUser {
        AuthenticatedUser {
            user_id: Uuid::new_v4(),
            role,
        }
    }

    #[test]
    fn test_require_role_allowed() {
        let user = make_user(UserRole::Admin);
        assert!(require_role(&user, &[UserRole::Admin]).is_ok());
    }

    #[test]
    fn test_require_role_multiple_allowed() {
        let user = make_user(UserRole::Client);
        assert!(require_role(&user, &[UserRole::Client, UserRole::Merchant]).is_ok());
    }

    #[test]
    fn test_require_role_forbidden() {
        let user = make_user(UserRole::Client);
        assert!(require_role(&user, &[UserRole::Admin]).is_err());
    }

    #[test]
    fn test_require_role_empty_roles_forbidden() {
        let user = make_user(UserRole::Admin);
        assert!(require_role(&user, &[]).is_err());
    }

    #[test]
    fn test_require_role_all_roles() {
        let user = make_user(UserRole::Driver);
        let all = [
            UserRole::Client,
            UserRole::Merchant,
            UserRole::Driver,
            UserRole::Agent,
            UserRole::Admin,
        ];
        assert!(require_role(&user, &all).is_ok());
    }
}
