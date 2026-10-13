import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import Message from '../components/common/Message'
import Spinner from '../components/common/Spinner'

const CHAMPS_VIDES = {
  prenom: '',
  nom: '',
  email: '',
  telephone: '',
  password: '',
  password_confirm: '',
  role: 'producteur',
}

const ERREURS_VIDES = {}

function normaliserChamps(data) {
  const erreurs = {}
  if (!data.email) {
    erreurs.email = ['L’adresse e-mail est obligatoire.']
  }
  if (!data.password) {
    erreurs.password = ['Le mot de passe est obligatoire.']
  } else if (data.password.length < 8) {
    erreurs.password = ['Le mot de passe doit contenir au moins 8 caractères.']
  } else if (data.password !== data.password_confirm) {
    erreurs.password_confirm = ['Les deux mots de passe ne correspondent pas.']
  }
  return erreurs
}

export default function Inscription() {
  const { inscription } = useAuth()
  const navigate = useNavigate()
  const [formulaire, setFormulaire] = useState(CHAMPS_VIDES)
  const [erreurs, setErreurs] = useState(ERREURS_VIDES)
  const [erreurGlobale, setErreurGlobale] = useState('')
  const [envoi, setEnvoi] = useState(false)

  function handleChange(champ) {
    return (evenement) => {
      const valeur = evenement.target.value
      setFormulaire((precedent) => ({ ...precedent, [champ]: valeur }))
    }
  }

  async function handleSubmit(evenement) {
    evenement.preventDefault()
    setErreurGlobale('')

    const erreursLocales = normaliserChamps(formulaire)
    setErreurs(erreursLocales)
    if (Object.keys(erreursLocales).length > 0) return

    setEnvoi(true)
    try {
      await inscription({
        prenom: formulaire.prenom,
        nom: formulaire.nom,
        email: formulaire.email,
        telephone: formulaire.telephone,
        password: formulaire.password,
        role: formulaire.role,
      })
      navigate('/connexion', {
        replace: true,
        state: { message: 'Compte créé avec succès. Vous pouvez maintenant vous connecter.' },
      })
    } catch (error) {
      const data = error?.response?.data
      if (data && typeof data === 'object') {
        setErreurs(data)
        const premier = Object.values(data).flat().find(Boolean)
        if (premier) setErreurGlobale(String(premier))
      } else {
        setErreurGlobale('Inscription impossible. Veuillez réessayer.')
      }
    } finally {
      setEnvoi(false)
    }
  }

  return (
    <div className="page-auth">
      <div className="auth-carte auth-carte-large">
        <div className="auth-entete">
          <span className="auth-logo" aria-hidden="true">🌱</span>
          <h1>Créer un compte</h1>
          <p>Rejoignez la plateforme Smart AgroTech Sénégal.</p>
        </div>

        {erreurGlobale && <Message type="erreur">{erreurGlobale}</Message>}

        <form onSubmit={handleSubmit} className="formulaire formulaire-grille" noValidate>
          <div className="champ">
            <label htmlFor="prenom">Prénom</label>
            <input id="prenom" type="text" required value={formulaire.prenom} onChange={handleChange('prenom')} />
            {erreurs.prenom && <span className="champ-erreur">{erreurs.prenom}</span>}
          </div>

          <div className="champ">
            <label htmlFor="nom">Nom</label>
            <input id="nom" type="text" required value={formulaire.nom} onChange={handleChange('nom')} />
            {erreurs.nom && <span className="champ-erreur">{erreurs.nom}</span>}
          </div>

          <div className="champ champ-plein">
            <label htmlFor="email">Adresse e-mail</label>
            <input id="email" type="email" required value={formulaire.email} onChange={handleChange('email')} placeholder="exemple@domaine.sn" />
            {erreurs.email && <span className="champ-erreur">{erreurs.email}</span>}
          </div>

          <div className="champ">
            <label htmlFor="telephone">Téléphone</label>
            <input id="telephone" type="tel" value={formulaire.telephone} onChange={handleChange('telephone')} placeholder="+221 …" />
            {erreurs.telephone && <span className="champ-erreur">{erreurs.telephone}</span>}
          </div>

          <div className="champ">
            <label htmlFor="role">Je suis</label>
            <select id="role" value={formulaire.role} onChange={handleChange('role')}>
              <option value="producteur">Agriculteur / Éleveur</option>
              <option value="acheteur">Acheteur</option>
            </select>
            {erreurs.role && <span className="champ-erreur">{erreurs.role}</span>}
          </div>

          <div className="champ">
            <label htmlFor="password">Mot de passe</label>
            <input id="password" type="password" autoComplete="new-password" required value={formulaire.password} onChange={handleChange('password')} />
            {erreurs.password && <span className="champ-erreur">{erreurs.password}</span>}
          </div>

          <div className="champ">
            <label htmlFor="password_confirm">Confirmer le mot de passe</label>
            <input id="password_confirm" type="password" autoComplete="new-password" required value={formulaire.password_confirm} onChange={handleChange('password_confirm')} />
            {erreurs.password_confirm && <span className="champ-erreur">{erreurs.password_confirm}</span>}
          </div>

          <div className="champ-plein">
            <button type="submit" className="btn btn-primaire btn-plein" disabled={envoi}>
              {envoi ? <Spinner /> : 'Créer mon compte'}
            </button>
          </div>
        </form>

        <p className="auth-pied">
          Vous avez déjà un compte ? <Link to="/connexion">Se connecter</Link>
        </p>
      </div>
    </div>
  )
}
