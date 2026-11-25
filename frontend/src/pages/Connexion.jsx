import { useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import Message from '../components/common/Message'
import Spinner from '../components/common/Spinner'
import aeImg from '../assets/img/ae.jpeg'

export default function Connexion() {
  const { connexion } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [identifiants, setIdentifiants] = useState({ email: '', password: '' })
  const [erreur, setErreur] = useState('')
  const [envoi, setEnvoi] = useState(false)

  const destination = location.state?.from?.pathname || '/tableau-de-bord'

  function handleChange(champ) {
    return (evenement) => {
      setIdentifiants((precedent) => ({ ...precedent, [champ]: evenement.target.value }))
    }
  }

  async function handleSubmit(evenement) {
    evenement.preventDefault()
    setErreur('')
    setEnvoi(true)
    try {
      await connexion(identifiants)
      navigate(destination, { replace: true })
    } catch (error) {
      setErreur(messageErreur(error))
    } finally {
      setEnvoi(false)
    }
  }

  return (
    <div className="page-auth">
      <div className="auth-container">
        {/* Image de gauche avec hero.jpg */}
        <div className="auth-image-left">
          <img
            src={aeImg}
            alt="Bannière d'accueil Smart AgroTech"
            loading="eager"
          />
        </div>

        {/* Formulaire */}
        <div className="auth-formulaire-zone">
          <div className="auth-carte">
            <div className="auth-entete">
              <h1>Connexion</h1>
            </div>

            {location.state?.message && <Message type="succes">{location.state.message}</Message>}
            {erreur && <Message type="erreur">{erreur}</Message>}

            <form onSubmit={handleSubmit} className="formulaire" noValidate>
              <div className="champ">
                <label htmlFor="email">Adresse e-mail</label>
                <input
                  id="email"
                  type="email"
                  name="email"
                  autoComplete="email"
                  required
                  value={identifiants.email}
                  onChange={handleChange('email')}
                  placeholder="exemple@domaine.sn"
                />
              </div>

              <div className="champ">
                <label htmlFor="password">Mot de passe</label>
                <input
                  id="password"
                  type="password"
                  name="password"
                  autoComplete="current-password"
                  required
                  value={identifiants.password}
                  onChange={handleChange('password')}
                  placeholder="Votre mot de passe"
                />
              </div>

              <button type="submit" className="btn btn-primaire btn-plein btn-grand" disabled={envoi}>
                {envoi ? <Spinner /> : 'Se connecter'}
              </button>
            </form>

            <p className="auth-pied">
              Pas encore de compte ? <Link to="/inscription">Créer un compte</Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
