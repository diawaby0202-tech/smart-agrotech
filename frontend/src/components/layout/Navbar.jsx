import { useState } from 'react'
import { Link, NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'

function initiales(utilisateur) {
  if (!utilisateur) return '?'
  const p = utilisateur.prenom?.charAt(0) || ''
  const n = utilisateur.nom?.charAt(0) || ''
  return (p + n).toUpperCase()
}

export default function Navbar() {
  const { estConnecte, estAdmin, utilisateur, deconnexion } = useAuth()
  const [menuOuvert, setMenuOuvert] = useState(false)
  const navigate = useNavigate()

  function handleDeconnexion() {
    deconnexion()
    setMenuOuvert(false)
    navigate('/')
  }

  function fermerMenu() {
    setMenuOuvert(false)
  }

  const lienClasses = ({ isActive }) => (isActive ? 'nav-lien actif' : 'nav-lien')

  return (
    <header className="navbar">
      <div className="navbar-interne">
        <Link to="/" className="navbar-marque" onClick={fermerMenu}>
          <span className="navbar-logo" aria-hidden="true">🌱</span>
          <span className="navbar-titre">Smart AgroTech</span>
        </Link>

        <button
          type="button"
          className="navbar-burger"
          aria-label="Ouvrir le menu"
          aria-expanded={menuOuvert}
          onClick={() => setMenuOuvert((ouvert) => !ouvert)}
        >
          <span />
          <span />
          <span />
        </button>

        <nav className={`navbar-nav ${menuOuvert ? 'ouvert' : ''}`}>
          <NavLink to="/" end className={lienClasses} onClick={fermerMenu}>
            Accueil
          </NavLink>
          <NavLink to="/cultures" className={lienClasses} onClick={fermerMenu}>
            Cultures
          </NavLink>
          <NavLink to="/elevage" className={lienClasses} onClick={fermerMenu}>
            Élevage
          </NavLink>
          <NavLink to="/alertes" className={lienClasses} onClick={fermerMenu}>
            Alertes
          </NavLink>
          <NavLink to="/marche" className={lienClasses} onClick={fermerMenu}>
            Marché
          </NavLink>

          {estConnecte ? (
            <div className="navbar-utilisateur">
              <NavLink to="/tableau-de-bord" className={lienClasses} onClick={fermerMenu}>
                <span className="navbar-avatar" aria-hidden="true">{initiales(utilisateur)}</span>
                Tableau de bord
              </NavLink>
              {estAdmin && (
                <NavLink to="/administration" className={lienClasses} onClick={fermerMenu}>
                  Administration
                </NavLink>
              )}
              <button type="button" className="btn btn-fantome" onClick={handleDeconnexion}>
                Déconnexion
              </button>
            </div>
          ) : (
            <div className="navbar-actions">
              <NavLink to="/connexion" className="btn btn-fantome" onClick={fermerMenu}>
                Connexion
              </NavLink>
              <NavLink to="/inscription" className="btn btn-primaire" onClick={fermerMenu}>
                Créer un compte
              </NavLink>
            </div>
          )}
        </nav>
      </div>
    </header>
  )
}
