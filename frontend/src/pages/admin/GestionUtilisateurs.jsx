import { useCallback, useEffect, useState } from 'react'
import { useAuth } from '../../context/AuthContext'
import {
  listerUtilisateurs,
  refuserUtilisateur,
  supprimerUtilisateur,
  suspendreUtilisateur,
  validerUtilisateur,
} from '../../api/adminService'
import Message from '../../components/common/Message'
import Spinner from '../../components/common/Spinner'

const LIBELLES_ROLE = {
  producteur: 'Agriculteur / Éleveur',
  acheteur: 'Acheteur',
  admin: 'Administrateur',
}

function messageErreur(error) {
  const data = error?.response?.data
  if (data?.detail) return data.detail
  if (data && typeof data === 'object') {
    return Object.values(data).flat().join(' · ')
  }
  return 'Action impossible.'
}

export default function GestionUtilisateurs() {
  const { utilisateur: utilisateurCourant } = useAuth()
  const [utilisateurs, setUtilisateurs] = useState([])
  const [filtres, setFiltres] = useState({ role: '', statut: '' })
  const [chargement, setChargement] = useState(true)
  const [erreur, setErreur] = useState('')
  const [succes, setSucces] = useState('')
  const [actionEnCours, setActionEnCours] = useState(null)

  const charger = useCallback(async () => {
    setChargement(true)
    setErreur('')
    try {
      const liste = await listerUtilisateurs(filtres)
      setUtilisateurs(Array.isArray(liste) ? liste : liste.results || [])
    } catch (error) {
      setErreur(messageErreur(error))
    } finally {
      setChargement(false)
    }
  }, [filtres])

  // Chargement initial et à chaque changement de filtre.
  // On utilise un flag d'annulation pour éviter d'écrire l'état après démontage,
  // et on ne déclenche aucun setState de façon synchrone dans l'effet.
  useEffect(() => {
    let ignore = false
    ;(async () => {
      try {
        const liste = await listerUtilisateurs(filtres)
        if (ignore) return
        setUtilisateurs(Array.isArray(liste) ? liste : liste.results || [])
        setErreur('')
      } catch (error) {
        if (ignore) return
        setErreur(messageErreur(error))
      } finally {
        if (!ignore) setChargement(false)
      }
    })()
    return () => {
      ignore = true
    }
  }, [filtres])

  async function appliquerAction(id, action, libelle) {
    setActionEnCours(`${id}-${libelle}`)
    setErreur('')
    setSucces('')
    try {
      await action(id)
      setSucces(`Action « ${libelle} » effectuée.`)
      await charger()
    } catch (error) {
      setErreur(messageErreur(error))
    } finally {
      setActionEnCours(null)
    }
  }

  return (
    <div className="page-admin">
      <div className="entete-page">
        <h1>Gestion des utilisateurs</h1>
        <p>Consultez, validez, suspendez ou supprimez les comptes de la plateforme.</p>
      </div>

      {succes && <Message type="succes">{succes}</Message>}
      {erreur && <Message type="erreur">{erreur}</Message>}

      <div className="barre-filtres">
        <div className="champ champ-inline">
          <label htmlFor="filtre-role">Rôle</label>
          <select
            id="filtre-role"
            value={filtres.role}
            onChange={(e) => setFiltres((f) => ({ ...f, role: e.target.value }))}
          >
            <option value="">Tous</option>
            <option value="producteur">Agriculteur / Éleveur</option>
            <option value="acheteur">Acheteur</option>
            <option value="admin">Administrateur</option>
          </select>
        </div>
        <div className="champ champ-inline">
          <label htmlFor="filtre-statut">Statut</label>
          <select
            id="filtre-statut"
            value={filtres.statut}
            onChange={(e) => setFiltres((f) => ({ ...f, statut: e.target.value }))}
          >
            <option value="">Tous</option>
            <option value="en_attente">En attente</option>
            <option value="valide">Validé</option>
            <option value="refuse">Refusé</option>
            <option value="suspendu">Suspendu</option>
          </select>
        </div>
      </div>

      {chargement ? (
        <div className="page-chargement"><Spinner taille={28} /></div>
      ) : utilisateurs.length === 0 ? (
        <p className="vide">Aucun utilisateur ne correspond à ces critères.</p>
      ) : (
        <TableauUtilisateurs
          utilisateurs={utilisateurs}
          utilisateurCourant={utilisateurCourant}
          actionEnCours={actionEnCours}
          appliquerAction={appliquerAction}
        />
      )}
    </div>
  )
}

function TableauUtilisateurs({ utilisateurs, utilisateurCourant, actionEnCours, appliquerAction }) {
  return (
    <div className="tableau-defilant">
      <table className="tableau">
        <thead>
          <tr>
            <th>Nom</th>
            <th>E-mail</th>
            <th>Rôle</th>
            <th>Statut</th>
            <th>Inscription</th>
            <th className="col-actions">Actions</th>
          </tr>
        </thead>
        <tbody>
          {utilisateurs.map((u) => {
            const estMoi = u.id === utilisateurCourant?.id
            return (
              <tr key={u.id}>
                <td>
                  {u.prenom} {u.nom}
                  {estMoi && <span className="badge badge-moi"> vous</span>}
                </td>
                <td>{u.email}</td>
                <td>{LIBELLES_ROLE[u.role] || u.role}</td>
                <td><span className={`badge statut-${u.statut}`}>{u.statut}</span></td>
                <td>{u.date_inscription ? new Date(u.date_inscription).toLocaleDateString('fr-FR') : '—'}</td>
                <td className="col-actions">
                  <div className="groupe-actions">
                    {u.statut === 'en_attente' && (
                      <>
                        <button
                          type="button"
                          className="btn btn-petit btn-succes"
                          disabled={actionEnCours}
                          onClick={() => appliquerAction(u.id, validerUtilisateur, 'valider')}
                        >
                          Valider
                        </button>
                        <button
                          type="button"
                          className="btn btn-petit btn-danger"
                          disabled={actionEnCours}
                          onClick={() => appliquerAction(u.id, refuserUtilisateur, 'refuser')}
                        >
                          Refuser
                        </button>
                      </>
                    )}
                    {u.statut === 'valide' && !estMoi && (
                      <button
                        type="button"
                        className="btn btn-petit btn-attention"
                        disabled={actionEnCours}
                        onClick={() => appliquerAction(u.id, suspendreUtilisateur, 'suspendre')}
                      >
                        Suspendre
                      </button>
                    )}
                    {!estMoi && (
                      <button
                        type="button"
                        className="btn btn-petit btn-danger"
                        disabled={actionEnCours}
                        onClick={() => appliquerAction(u.id, supprimerUtilisateur, 'supprimer')}
                      >
                        Supprimer
                      </button>
                    )}
                    {actionEnCours?.startsWith(`${u.id}-`) && <Spinner taille={16} />}
                  </div>
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
