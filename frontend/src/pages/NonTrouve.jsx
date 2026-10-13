import { Link } from 'react-router-dom'

export default function NonTrouve() {
  return (
    <div className="page-construction">
      <span className="construction-icone" aria-hidden="true">🧭</span>
      <h1>Page introuvable</h1>
      <p className="construction-description">
        La page que vous recherchez n'existe pas ou a été déplacée.
      </p>
      <div className="construction-actions">
        <Link to="/" className="btn btn-primaire">
          Retour à l'accueil
        </Link>
      </div>
    </div>
  )
}
