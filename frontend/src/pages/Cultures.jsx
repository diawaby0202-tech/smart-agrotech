import { useState } from 'react'
import parcelleImg from '../assets/img/cultures.jpg'
import BandeauApercu from '../components/common/BandeauApercu'

/* ============================================================
   MODULE CULTURES — maquette de démonstration
   Données d'exemple (100 % fictives) pour la soutenance.
   Aucune connexion backend : tout est statique et visuel.
   ============================================================ */

const parcelles = [
  {
    id: 1,
    culture: 'Mil',
    emoji: '🌾',
    superficie: 3.5,
    dateSemis: '12 juin 2026',
    recolte: 'Octobre 2026',
    statut: 'Croissance',
    progression: 62,
    prochaineEtape: 'Désherbage — dans 3 jours',
  },
  {
    id: 2,
    culture: 'Arachide',
    emoji: '🥜',
    superficie: 2,
    dateSemis: '28 juin 2026',
    recolte: 'Septembre 2026',
    statut: 'Floraison',
    progression: 78,
    prochaineEtape: 'Traitement fongicide — dans 6 jours',
  },
  {
    id: 3,
    culture: 'Maïs',
    emoji: '🌽',
    superficie: 1.2,
    dateSemis: '5 juillet 2026',
    recolte: 'Octobre 2026',
    statut: 'Semis',
    progression: 15,
    prochaineEtape: 'Irrigation — demain',
  },
]

const couleurStatut = {
  Semis: 'semis',
  Croissance: 'croissance',
  Floraison: 'floraison',
  Récolte: 'recolte',
}

export default function Cultures() {
  const [filtre, setFiltre] = useState('Toutes')
  const culturesAffichees =
    filtre === 'Toutes' ? parcelles : parcelles.filter((p) => p.culture === filtre)
  const surfaceTotale = parcelles.reduce((total, p) => total + p.superficie, 0)
  const culturesUniques = ['Toutes', ...new Set(parcelles.map((p) => p.culture))]

  return (
    <div className="page-module">
      <BandeauApercu
        icone="🌾"
        titre="Suivi des cultures"
        texte="Suivez vos parcelles de la semence à la récolte, anticipez chaque étape."
      />

      <div className="stats-module">
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">{parcelles.length}</span>
          <span className="stat-pilule-libelle">Parcelles suivies</span>
        </div>
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">{surfaceTotale.toFixed(1)} ha</span>
          <span className="stat-pilule-libelle">Surface totale</span>
        </div>
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">Oct.</span>
          <span className="stat-pilule-libelle">Prochaine récolte</span>
        </div>
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">3</span>
          <span className="stat-pilule-libelle">Rappels actifs</span>
        </div>
      </div>

      <div className="filtres-module">
        {culturesUniques.map((culture) => (
          <button
            key={culture}
            type="button"
            className={`puce-filtre ${filtre === culture ? 'actif' : ''}`}
            onClick={() => setFiltre(culture)}
          >
            {culture}
          </button>
        ))}
        <button type="button" className="btn btn-primaire btn-petit puce-action" disabled>
          + Nouvelle parcelle
        </button>
      </div>

      <div className="grille-parcelles">
        {culturesAffichees.map((parcelle) => (
          <article key={parcelle.id} className="carte-parcelle">
            <div className="carte-parcelle-visuel">
              <img src={parcelleImg} alt="" loading="lazy" />
              <span className="carte-parcelle-emoji" aria-hidden="true">{parcelle.emoji}</span>
              <span className={`etiquette-statut etiquette-${couleurStatut[parcelle.statut]}`}>
                {parcelle.statut}
              </span>
            </div>
            <div className="carte-parcelle-corps">
              <h3>{parcelle.culture}</h3>
              <div className="carte-parcelle-meta">
                <span>📐 {parcelle.superficie} ha</span>
                <span>🌱 Semis : {parcelle.dateSemis}</span>
                <span>🧺 Récolte : {parcelle.recolte}</span>
              </div>
              <div className="progression">
                <div className="progression-entete">
                  <span>Avancement</span>
                  <span>{parcelle.progression}%</span>
                </div>
                <div className="progression-piste">
                  <span className="progression-remplissage" style={{ width: `${parcelle.progression}%` }} />
                </div>
              </div>
              <p className="carte-parcelle-rappel">🔔 {parcelle.prochaineEtape}</p>
            </div>
          </article>
        ))}
      </div>
    </div>
  )
}
