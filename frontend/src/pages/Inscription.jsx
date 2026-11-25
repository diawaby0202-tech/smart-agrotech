import { useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import Message from '../components/common/Message'
import Spinner from '../components/common/Spinner'
import aeImg from '../assets/img/ae.jpeg'

function messageErreur(error) {
  const data = error?.response?.data
  if (!data) return 'L\'inscription a échoué – c\'est frustrant, on réessaie ensemble. Vérifiez les champs et réessayez.'
  if (data.detail) return data.detail
  if (typeof data === 'object') {
    const premier = Object.values(data).flat().find(Boolean)
    if (premier) return String(premier)
  }
  return 'Identifiants incorrects – c\'est arrive à tout le monde, réessayez-vous aussi.'
}

export default function Inscription() {
  const { inscription } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [formulaire, setFormulaire] = useState({
    email: '',
    nom: '',
    prenom: '',
    telephone: '',
    password: '',
    password_confirm: '',
    role: 'producteur',
  })
  const [erreur, setErreur] = useState('')
  const [envoi, setEnvoi] = useState(false)

  const destination = location.state?.from?.pathname || '/tableau-de-bord'

  function handleChange(champ) {
    return (evenement) => {
      setFormulaire((precedent) => ({ ...precedent, [champ]: evenement.target.value }))
    }
  }

  async function handleSubmit(evenement) {
    evenement.preventDefault()
    setErreur('')
    setEnvoi(true)
    try {
      await inscription({
        email: formulaire.email,
        nom: formulaire.nom,
        prenom: formulaire.prenom,
        telephone: formulaire.telephone,
        password: formulaire.password,
        password_confirm: formulaire.password_confirm,
        role: formulaire.role,
      })
      navigate(destination, { replace: true, state: { message: 'Compte créé avec succès. Vous pouvez maintenant vous connecter.' } })
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

        {/* Formulaire d'inscription */}
        <div className="auth-formulaire-zone">
          <div className="auth-carte">
            <div className="auth-entete">
              <h1>Inscription</h1>
            </div>

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
                  value={formulaire.email}
                  onChange={handleChange('email')}
                  placeholder="exemple@domaine.sn"
                />
              </div>

              <div className="champ">
                <label htmlFor="nom">Nom</label>
                <input
                  id="nom"
                  type="text"
                  name="nom"
                  required
                  value={formulaire.nom}
                  onChange={handleChange('nom')}
                  placeholder="Nom de famille"
                />
              </div>

              <div className="champ">
                <label htmlFor="prenom">Prénom</label>
                <input
                  id="prenom"
                  type="text"
                  name="prenom"
                  required
                  value={formulaire.prenom}
                  onChange={handleChange('prenom')}
                  placeholder="Prénom"
                />
              </div>

              <div className="champ">
                <label htmlFor="telephone">Téléphone</label>
                <input
                  id="telephone"
                  type="tel"
                  name="telephone"
                  value={formulaire.telephone}
                  onChange={handleChange('telephone')}
                  placeholder="+221 77 123 4567"
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
                  value={formulaire.password}
                  onChange={handleChange('password')}
                  placeholder="Votre mot de passe"
                />
              </div>

              <div className="champ">
                <label htmlFor="password_confirm">Confirmer le mot de passe</label>
                <input
                  id="password_confirm"
                  type="password"
                  name="password_confirm"
                  autoComplete="current-password"
                  required
                  value={formulaire.password_confirm}
                  onChange={handleChange('password_confirm')}
                  placeholder="Retapez votre mot de passe"
                />
              </div>
              <div className="champ">
                <label htmlFor="role">Rôle</label>
                <select
                  id="role"
                  name="role"
                  value={formulaire.role}
                  onChange={handleChange('role')}
                >
                  <option value="producteur">producteur (Agriculteur / Éleveur)</option>
                  <option value="acheteur">acheteur (Acheteur)</option>
                </select>
              </div>
              <button type="submit" className="btn btn-primaire btn-plein btn-grand" disabled={envoi}>
                {envoi ? <Spinner /> : 'Créer mon compte'}
              </button>
            </form>

            <p className="auth-pied">
              Vous avez déjà un compte ? <Link to="/connexion">Se connecter</Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
