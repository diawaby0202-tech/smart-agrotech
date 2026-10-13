import { Link } from 'react-router-dom'

/**
 * Page générique affichée pour un module dont l'API backend n'est pas encore
 * disponible. Évite d'afficher de fausses données en attendant l'intégration
 * avec Django (modules cultures, élevage, alertes, marché).
 */
export default function PageEnConstruction({ icone, titre, description, fonctionnalites = [] }) {
  return (
    <div className="page-construction">
      <span className="construction-icone" aria-hidden="true">{icone}</span>
      <h1>{titre}</h1>
      <p className="construction-description">{description}</p>

      {fonctionnalites.length > 0 && (
        <ul className="construction-liste">
          {fonctionnalites.map((fonctionnalite) => (
            <li key={fonctionnalite}>✓ {fonctionnalite}</li>
          ))}
        </ul>
      )}

      <span className="badge badge-bientot">Bientôt disponible</span>

      <div className="construction-actions">
        <Link to="/tableau-de-bord" className="btn btn-secondaire">
          Retour au tableau de bord
        </Link>
      </div>
    </div>
  )
}
