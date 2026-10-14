import { useEffect, useState } from 'react'
import { obtenirStatistiques } from '../../api/adminService'
import Message from '../../components/common/Message'
import Spinner from '../../components/common/Spinner'

const LIBELLES_STATUT = {
  en_attente: 'En attente',
  valide: 'Validés',
  refuse: 'Refusés',
  suspendu: 'Suspendus',
}

export default function Statistiques() {
  const [stats, setStats] = useState(null)
  const [chargement, setChargement] = useState(true)
  const [erreur, setErreur] = useState('')

  useEffect(() => {
    let actif = true
    async function charger() {
      try {
        const data = await obtenirStatistiques()
        if (actif) setStats(data)
      } catch {
        if (actif) setErreur('Impossible de charger les statistiques.')
      } finally {
        if (actif) setChargement(false)
      }
    }
    charger()
    return () => {
      actif = false
    }
  }, [])

  return (
    <div className="page-admin">
      <div className="entete-page">
        <h1>Statistiques de la plateforme</h1>
        <p>Vue d’ensemble de l’utilisation de Smart AgroTech Sénégal.</p>
      </div>

      {erreur && <Message type="erreur">{erreur}</Message>}

      {chargement ? (
        <div className="page-chargement"><Spinner taille={28} /></div>
      ) : stats ? (
        <>
          <div className="grille-stats">
            <div className="carte-stat">
              <span className="carte-stat-valeur">{stats.total_utilisateurs}</span>
              <span className="carte-stat-libelle">Utilisateurs inscrits</span>
            </div>
            <div className="carte-stat">
              <span className="carte-stat-valeur">{stats.nouveaux_30_jours}</span>
              <span className="carte-stat-libelle">Nouveaux (30 jours)</span>
            </div>
          </div>

          <div className="stats-details">
            <section className="carte">
              <h2>Par rôle</h2>
              <ul className="liste-barres">
                {Object.entries(stats.par_role || {}).map(([role, nombre]) => (
                  <li key={role}>
                    <span className="barre-libelle">{role}</span>
                    <span className="barre-piste">
                      <span className="barre-remplissage" style={{ width: `${pourcentage(nombre, stats.total_utilisateurs)}%` }} />
                    </span>
                    <span className="barre-valeur">{nombre}</span>
                  </li>
                ))}
              </ul>
            </section>

            <section className="carte">
              <h2>Par statut</h2>
              <ul className="liste-barres">
                {Object.entries(stats.par_statut || {}).map(([statut, nombre]) => (
                  <li key={statut}>
                    <span className="barre-libelle">{LIBELLES_STATUT[statut] || statut}</span>
                    <span className="barre-piste">
                      <span className={`barre-remplissage barre-${statut}`} style={{ width: `${pourcentage(nombre, stats.total_utilisateurs)}%` }} />
                    </span>
                    <span className="barre-valeur">{nombre}</span>
                  </li>
                ))}
              </ul>
            </section>
          </div>
        </>
      ) : null}
    </div>
  )
}

function pourcentage(valeur, total) {
  if (!total) return 0
  return Math.round((valeur / total) * 100)
}
