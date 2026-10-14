import { Link } from 'react-router-dom'

/**
 * Page d'atterrissage d'un module en cours de développement.
 * Design soigné (soutenance) : visuel, accroche, description et aperçu
 * des capacités du module, sans référence technique (RF-xx).
 */
export default function PageEnConstruction({
  icone,
  titre,
  accroche,
  description,
  fonctionnalites = [],
}) {
  return (
    <div className="module-hero">
      <div className="module-hero-fond" aria-hidden="true" />

      <div className="module-hero-contenu">
        <span className="badge badge-construction">
          <span className="point-pulse" aria-hidden="true" />
          En cours de développement
        </span>

        <div className="module-illustration" aria-hidden="true">
          <span className="module-illustration-icone">{icone}</span>
        </div>

        <h1 className="module-titre">{titre}</h1>
        {accroche && <p className="module-accroche">{accroche}</p>}
        <p className="module-description">{description}</p>

        {fonctionnalites.length > 0 && (
          <div className="module-apercu">
            <span className="module-apercu-titre">Ce que vous pourrez faire</span>
            <ul className="module-apercu-liste">
              {fonctionnalites.map((fonctionnalite) => (
                <li key={fonctionnalite}>
                  <span className="check-icone" aria-hidden="true">✓</span>
                  {fonctionnalite}
                </li>
              ))}
            </ul>
          </div>
        )}

        <div className="module-actions">
          <Link to="/tableau-de-bord" className="btn btn-primaire btn-grand">
            Retour au tableau de bord
          </Link>
        </div>
      </div>
    </div>
  )
}

