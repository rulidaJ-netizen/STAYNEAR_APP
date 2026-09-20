const AUTHENTICATED_ROLE = "authenticated";

function withAuthenticatedRole(claims = {}) {
  return {...claims, role: AUTHENTICATED_ROLE};
}

module.exports = {AUTHENTICATED_ROLE, withAuthenticatedRole};
