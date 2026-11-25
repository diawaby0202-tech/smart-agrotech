import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

/**
 * Route rÃ©servÃ©e aux visiteurs non connectÃ©s (connexion, inscription).
 * Redirige l'utilisateur dÃ©jÃ  authentifiÃ© vers son tableau de bord.
 */
export function RoutePublique({ children }) {
  const { estConnecte, chargement } = useAuth()
  const location = useLocation()

  if (chargement) {
    return <div className="page-chargement">Chargementâ€¦</div>
  }

  if (estConnecte) {
    const origine = location.state?.from?.pathname || '/tableau-de-bord'
    return <Navigate to={origine} replace />
  }

  return children
}

/**
 * Route protÃ©gÃ©e : exige une session valide.
 * `roles` (optionnel) limite l'accÃ¨s Ã  certains rÃ´les (ex. ['admin']).
 */
export function RouteProtegee({ children, roles = [] }) {
  const { estConnecte, chargement, utilisateur } = useAuth()
  const location = useLocation()

  if (chargement) {
    return <div className="page-chargement">Chargementâ€¦</div>
  }

  if (!estConnecte) {
    return <Navigate to="/connexion" state={{ from: location }} replace />
  }

  if (roles.length > 0 && !roles.includes(utilisateur?.role)) {
    return <Navigate to="/tableau-de-bord" replace />
  }

  return children
}

