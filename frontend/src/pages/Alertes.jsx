import meteoImg from '../assets/img/meteo.jpg'
import BandeauApercu from '../components/common/BandeauApercu'

/* ============================================================
   MODULE ALERTES — maquette de démonstration
   Données d’exemple (100 % fictives) pour la soutenance.
   ============================================================ */

const previsions = [
  { jour: 'Aujourd’hui', icone: '🌤️', max: 34, min: 24 },
  { jour: 'Demain', icone: '☀️', max: 36, min: 25 },
  { jour: 'Mercredi', icone: '⛈️', max: 31, min: 23 },
  { jour: 'Jeudi', icone: '🌦️', max: 30, min: 23 },
  { jour: 'Vendredi', icone: '☀️', max: 35, min: 24 },
]

const alertes = [
  {
    id: 1,
    niveau: 'risque',
    type: 'Fortes pluies orageuses',
    icone: '⛈️',
    zone: 'Région de Thiès',
    date: 'Aujourd’hui, 18h',
    conseil: 'Récoltez si possible les cultures mûres et protégez le bétail.',
  },
  {
    id: 2,
    niveau: 'vigilance',
    type: 'Vague de chaleur',
    icone: '🌡️',
    zone: 'Région de Kaolack',
    date: 'Demain',
    conseil: 'Privilégiez l’irrigation tôt le matin ou en fin de journée.',
  },
  {
    id: 3,
    niveau: 'info',
    type: 'Début hivernage',
    icone: '🌧️',
    zone: 'Région de Dakar',
    date: 'Cette semaine',
    conseil: 'Moment propice pour lancer les semis de mil et d’arachide.',
  },
]

const libelleNiveau = { risque: 'Risque', vigilance: 'Vigilance', info: 'Information' }

export default function Alertes() {
  return (
    <div className="page-module">
      <BandeauApercu
        icone="⛅"
        titre="Alertes météo & environnementales"
        texte="La météo de votre zone et des alertes précoces pour protéger vos activités."
      />

      <section className="carte carte-meteo">
        <div className="carte-meteo-entete">
          <div>
            <h2>📍 Kaolack, Sénégal</h2>
            <p>Mise à jour il y a quelques instants</p>
          </div>
          <div className="carte-meteo-actuel">
            <span className="carte-meteo-temp">34°</span>
            <span className="carte-meteo-etat">🌤️ Ensoleillé</span>
          </div>
        </div>
        <div className="meteo-previsions">
          {previsions.map((prevision) => (
            <div key={prevision.jour} className="meteo-jour">
              <span className="meteo-jour-nom">{prevision.jour}</span>
              <span className="meteo-jour-icone" aria-hidden="true">{prevision.icone}</span>
              <span className="meteo-jour-temps">
                <strong>{prevision.max}°</strong> / {prevision.min}°
              </span>
            </div>
          ))}
        </div>
        <img src={meteoImg} alt="" className="carte-meteo-image" loading="lazy" />
      </section>

      <h2 className="titre-section-module">🔔 Alertes récentes</h2>
      <div className="liste-alertes">
        {alertes.map((alerte) => (
          <article key={alerte.id} className={`carte-alerte alerte-${alerte.niveau}`}>
            <span className="carte-alerte-icone" aria-hidden="true">{alerte.icone}</span>
            <div className="carte-alerte-corps">
              <div className="carte-alerte-entete">
                <h3>{alerte.type}</h3>
                <span className={`etiquette-statut etiquette-${alerte.niveau === 'risque' ? 'floraison' : alerte.niveau === 'vigilance' ? 'semis' : 'croissance'}`}>
                  {libelleNiveau[alerte.niveau]}
                </span>
              </div>
              <p className="carte-alerte-meta">
                📍 {alerte.zone} · 🕒 {alerte.date}
              </p>
              <p className="carte-alerte-conseil">💡 {alerte.conseil}</p>
            </div>
          </article>
        ))}
      </div>
    </div>
  )
}