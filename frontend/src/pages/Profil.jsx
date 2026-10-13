import { useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { modifierProfil } from '../api/authService'
import Message from '../components/common/Message'
import Spinner from '../components/common/Spinner'

function messageErreur(error) {
  const data = error?.response?.data
  if (data && typeof data === 'object') {
    return Object.entries(data)
      .map(([champ, messages]) => `${champ} : ${String(messages).flat().join(', ')}`)
      .join(' · ')
  }
  return 'Mise à jour impossible. Veuillez réessayer.'
}

export default function Profil() {
  const { utilisateur, modifierUtilisateurLocal, rafraichirProfil } = useAuth()
  const [formulaire, setFormulaire] = useState({
    prenom: utilisateur?.prenom || '',
    nom: utilisateur?.nom || '',
    telephone: utilisateur?.telephone || '',
  })
  const [succes, setSucces] = useState('')
  const [erreur, setErreur] = useState('')
  const [envoi, setEnvoi] = useState(false)

  function handleChange(champ) {
    return (evenement) => {
      setFormulaire((precedent) => ({ ...precedent, [champ]: evenement.target.value }))
    }
  }

  async function handleSubmit(evenement) {
    evenement.preventDefault()
    setSucces('')
    setErreur('')
    setEnvoi(true)
    try {
      const profil = await modifierProfil(formulaire)
      modifierUtilisateurLocal(profil)
      await rafraichirProfil()
      setSucces('Profil mis à jour avec succès.')
    } catch (error) {
      setErreur(messageErreur(error))
    } finally {
      setEnvoi(false)
    }
  }

  const LIBELLES_ROLE = {
    producteur: 'Agriculteur / Éleveur',
    acheteur: 'Acheteur',
    admin: 'Administrateur',
  }

  return (
    <div className="page-profil">
      <div className="entete-page">
        <h1>Mon profil</h1>
        <p>Consultez et modifiez vos informations personnelles.</p>
      </div>

      <div className="profil-grille">
        <section className="carte">
          <h2>Informations</h2>
          <dl className="liste-infos">
            <div>
              <dt>Rôle</dt>
              <dd>{LIBELLES_ROLE[utilisateur?.role] || utilisateur?.role}</dd>
            </div>
            <div>
              <dt>Statut du compte</dt>
              <dd>
                <span className={`badge statut-${utilisateur?.statut}`}>
                  {utilisateur?.statut || '—'}
                </span>
              </dd>
            </div>
            <div>
              <dt>E-mail</dt>
              <dd>{utilisateur?.email}</dd>
            </div>
            <div>
              <dt>Membre depuis</dt>
              <dd>
                {utilisateur?.date_inscription
                  ? new Date(utilisateur.date_inscription).toLocaleDateString('fr-FR')
                  : '—'}
              </dd>
            </div>
          </dl>
        </section>

        <section className="carte">
          <h2>Modifier mes informations</h2>
          {succes && <Message type="succes">{succes}</Message>}
          {erreur && <Message type="erreur">{erreur}</Message>}
          <form onSubmit={handleSubmit} className="formulaire">
            <div className="champ">
              <label htmlFor="profil-prenom">Prénom</label>
              <input id="profil-prenom" type="text" value={formulaire.prenom} onChange={handleChange('prenom')} required />
            </div>
            <div className="champ">
              <label htmlFor="profil-nom">Nom</label>
              <input id="profil-nom" type="text" value={formulaire.nom} onChange={handleChange('nom')} required />
            </div>
            <div className="champ">
              <label htmlFor="profil-telephone">Téléphone</label>
              <input id="profil-telephone" type="tel" value={formulaire.telephone} onChange={handleChange('telephone')} placeholder="+221 …" />
            </div>
            <button type="submit" className="btn btn-primaire" disabled={envoi}>
              {envoi ? <Spinner /> : 'Enregistrer'}
            </button>
          </form>
        </section>
      </div>
    </div>
  )
}
