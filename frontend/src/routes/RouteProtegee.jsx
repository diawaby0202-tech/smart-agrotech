import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

/**
 * Route réservée aux visiteurs non connectés (connexion, inscription).
 * Redirige l'utilisateur déjà authentifié vers son tableau de bord.
 */
export function RoutePublique({ children }) {
  const { estConnecte, chargement } = useAuth()
  const location = useLocation()

  if (chargement) {
    return <div className="page-chargement">Chargement…</div>
  }

  if (estConnecte) {
    const origine = location.state?.from?.pathname || '/tableau-de-bord'
    return <Navigate to={origine} replace />
  }

  return children
}

/**
 * Route protégée : exige une session valide.
 * `roles` (optionnel) limite l'accès à certains rôles (ex. ['admin']).
 */
export function RouteProtegee({ children, roles = [] }) {
  const { estConnecte, chargement, utilisateur } = useAuth()
  const location = useLocation()

  if (chargement) {
    return <div className="page-chargement">Chargement…</div>
  }

  if (!estConnecte) {
    return <Navigate to="/connexion" state={{ from: location }} replace />
  }

  if (roles.length > 0 && !roles.includes(utilisateur?.role)) {
    return <Navigate to="/tableau-de-bord" replace />
  }

  return children
}
