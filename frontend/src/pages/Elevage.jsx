import { useState } from 'react'
import imgBovin from '../assets/img/elevage-bovin.jpg'
import imgCaprin from '../assets/img/elevage-caprin.jpg'
import imgOvin from '../assets/img/elevage-ovin.jpg'
import BandeauApercu from '../components/common/BandeauApercu'

/* ============================================================
   MODULE ELEVAGE — maquette de démonstration
   Données d’exemple (100 % fictives) pour la soutenance.
   ============================================================ */

const animaux = [
  {
    id: 1,
    nom: 'Vache N’Doul',
    espece: 'Bovin',
    emoji: '🐄',
    image: imgBovin,
    identifiant: 'BOV-001',
    age: '4 ans',
    sante: 'Bonne santé',
    etat: 'bon',
    prochainSoin: 'Vaccin fièvre aphteuse — le 25 oct.',
  },
  {
    id: 2,
    nom: 'Lot de 12 chèvres',
    espece: 'Caprin',
    emoji: '🐐',
    image: imgCaprin,
    identifiant: 'CAP-014',
    age: '1 à 2 ans',
    sante: 'Traitement en cours',
    etat: 'attention',
    prochainSoin: 'Vermifuge — à renouveler dans 5 jours',
  },
  {
    id: 3,
    nom: 'Bélier Djitt',
    espece: 'Ovin',
    emoji: '🐏',
    image: imgOvin,
    identifiant: 'OVI-007',
    age: '2 ans',
    sante: 'Bonne santé',
    etat: 'bon',
    prochainSoin: 'Contrôle vétérinaire — le 2 nov.',
  },
]

const libelleEtat = { bon: 'Bonne santé', attention: 'À surveiller', critique: 'Urgent' }

export default function Elevage() {
  const [especeActive, setEspeceActive] = useState('Tous')
  const especes = ['Tous', ...new Set(animaux.map((a) => a.espece))]
  const animauxAffiches =
    especeActive === 'Tous' ? animaux : animaux.filter((a) => a.espece === especeActive)

  return (
    <div className="page-module">
      <BandeauApercu
        icone="🐄"
        titre="Gestion de l’élevage"
        texte="Un troupeau en bonne santé, suivi au plus près : soins, reproduction, alertes."
      />

      <div className="stats-module">
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">{animaux.length}</span>
          <span className="stat-pilule-libelle">Fiches suivies</span>
        </div>
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">14</span>
          <span className="stat-pilule-libelle">Têtes au total</span>
        </div>
        <div className="stat-pilule stat-alerte">
          <span className="stat-pilule-valeur">1</span>
          <span className="stat-pilule-libelle">Soin à venir</span>
        </div>
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">3</span>
          <span className="stat-pilule-libelle">Mises bas ce mois</span>
        </div>
      </div>

      <div className="filtres-module">
        {especes.map((espece) => (
          <button
            key={espece}
            type="button"
            className={`puce-filtre ${especeActive === espece ? 'actif' : ''}`}
            onClick={() => setEspeceActive(espece)}
          >
            {espece}
          </button>
        ))}
        <button type="button" className="btn btn-primaire btn-petit puce-action" disabled>
          + Ajouter un animal
        </button>
      </div>

      <div className="grille-parcelles">
        {animauxAffiches.map((animal) => (
          <article key={animal.id} className="carte-parcelle">
            <div className="carte-parcelle-visuel">
              <img src={animal.image} alt={animal.nom} loading="lazy" />
              <span className="carte-parcelle-emoji" aria-hidden="true">{animal.emoji}</span>
              <span className={`etiquette-statut etiquette-${animal.etat === 'bon' ? 'croissance' : 'semis'}`}>
                {libelleEtat[animal.etat]}
              </span>
            </div>
            <div className="carte-parcelle-corps">
              <h3>{animal.nom}</h3>
              <div className="carte-parcelle-meta">
                <span>🏷️ {animal.espece} · {animal.identifiant}</span>
                <span>🎂 {animal.age}</span>
                <span>💚 {animal.sante}</span>
              </div>
              <p className="carte-parcelle-rappel">🔔 {animal.prochainSoin}</p>
            </div>
          </article>
        ))}
      </div>
    </div>
  )
}