import { useEffect, useState } from 'react'
import meteoImg from '../assets/img/meteo.jpg'
import '../styles-modules.css'
import BandeauApercu from '../components/common/BandeauApercu'
import Message from '../components/common/Message'
import Spinner from '../components/common/Spinner'
import { alertes, messageErreur, meteo } from '../api/modulesService'

/* MODULE ALERTES — données réelles (API /api/meteo/ et /api/alertes/) */

const CLE_VILLE = 'smart_agrotech_ville'

function villeEnregistree() {
  try {
    return localStorage.getItem(CLE_VILLE) || 'Dakar'
  } catch {
    return 'Dakar'
  }
}

function iconeMeteo(description = '') {
  const d = description.toLowerCase()
  if (d.includes('orage')) return '⛈️'
  if (d.includes('pluie') || d.includes('averse') || d.includes('bruine')) return '🌦️'
  if (d.includes('nuage') || d.includes('couvert') || d.includes('brume')) return '☁️'
  if (d.includes('dégagé') || d.includes('clair') || d.includes('soleil')) return '☀️'
  return '🌤️'
}

function nomJour(iso, index) {
  if (index === 0) return 'Aujourd’hui'
  if (index === 1) return 'Demain'
  const jour = new Date(`${iso}T00:00:00`).toLocaleDateString('fr-FR', { weekday: 'long' })
  return jour.charAt(0).toUpperCase() + jour.slice(1)
}

const NIVEAUX = {
  info: { libelle: 'Information', carte: 'info', etiquette: 'croissance' },
  attention: { libelle: 'Vigilance', carte: 'vigilance', etiquette: 'semis' },
  danger: { libelle: 'Risque', carte: 'risque', etiquette: 'floraison' },
}
const ICONES_TYPE = { meteo: '⛈️', vaccination: '💉', culture: '🌾', systeme: '🔔' }

function formaterDateHeure(iso) {
  return new Date(iso).toLocaleString('fr-FR', {
    day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit',
  })
}

export default function Alertes() {
  const [ville, setVille] = useState(villeEnregistree)
  const [saisie, setSaisie] = useState(villeEnregistree)
  // résultat de la météo, associé à la ville demandée (évite un setState synchrone)
  const [meteoEtat, setMeteoEtat] = useState({ ville: null, data: null, erreur: '' })

  const [liste, setListe] = useState([])
  const [erreur, setErreur] = useState('')
  const [info, setInfo] = useState('')
  const [chargement, setChargement] = useState(true)
  const [occupe, setOccupe] = useState(false)
  const [version, setVersion] = useState(0)
  const recharger = () => setVersion((v) => v + 1)

  useEffect(() => {
    let ignore = false
    ;(async () => {
      try {
        const donnees = await alertes.lister()
        if (ignore) return
        setListe(donnees)
        setErreur('')
      } catch (e) {
        if (ignore) return
        setErreur(messageErreur(e, 'Impossible de charger les alertes.'))
      } finally {
        if (!ignore) setChargement(false)
      }
    })()
    return () => {
      ignore = true
    }
  }, [version])

  useEffect(() => {
    let ignore = false
    ;(async () => {
      try {
        const data = await meteo.obtenir(ville)
        if (!ignore) setMeteoEtat({ ville, data, erreur: '' })
      } catch (e) {
        if (!ignore) {
          setMeteoEtat({ ville, data: null, erreur: messageErreur(e, 'Météo indisponible pour le moment.') })
        }
      }
    })()
    return () => {
      ignore = true
    }
  }, [ville])

  const chargementMeteo = meteoEtat.ville !== ville
  const prevision = chargementMeteo ? null : meteoEtat.data
  const erreurMeteo = chargementMeteo ? '' : meteoEtat.erreur

  function changerVille(evenement) {
    evenement.preventDefault()
    const nouvelle = saisie.trim()
    if (!nouvelle) return
    try {
      localStorage.setItem(CLE_VILLE, nouvelle)
    } catch {
      /* stockage indisponible : on continue sans mémoriser */
    }
    setVille(nouvelle)
  }

  async function action(fonction, messageSucces) {
    setOccupe(true)
    setInfo('')
    try {
      const resultat = await fonction()
      setInfo(typeof messageSucces === 'function' ? messageSucces(resultat) : messageSucces)
      recharger()
    } catch (e) {
      setErreur(messageErreur(e))
    } finally {
      setOccupe(false)
    }
  }

  const nonLues = liste.filter((a) => !a.lue).length
  const jours = prevision?.previsions ?? []
  const aujourdhui = jours[0]

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
            <h2>📍 {ville}, Sénégal</h2>
            <p>Prévisions sur 5 jours</p>
          </div>
          {aujourdhui && (
            <div className="carte-meteo-actuel">
              <span className="carte-meteo-temp">{Math.round(aujourdhui.temp_max)}°</span>
              <span className="carte-meteo-etat">
                {iconeMeteo(aujourdhui.description)} {aujourdhui.description}
              </span>
            </div>
          )}
        </div>

        <form className="meteo-formulaire" onSubmit={changerVille}>
          <input
            type="text"
            value={saisie}
            onChange={(e) => setSaisie(e.target.value)}
            placeholder="Ville (ex. Thiès, Kaolack…)"
            aria-label="Ville"
          />
          <button type="submit" className="btn btn-primaire btn-petit">Voir la météo</button>
        </form>

        {chargementMeteo && <Spinner taille={26} />}
        {erreurMeteo && <Message type="erreur">{erreurMeteo}</Message>}

        {jours.length > 0 && (
          <div className="meteo-previsions">
            {jours.map((jour, index) => (
              <div key={jour.date} className="meteo-jour">
                <span className="meteo-jour-nom">{nomJour(jour.date, index)}</span>
                <span className="meteo-jour-icone" aria-hidden="true">{iconeMeteo(jour.description)}</span>
                <span className="meteo-jour-temps">
                  <strong>{Math.round(jour.temp_max)}°</strong> / {Math.round(jour.temp_min)}°
                </span>
                {jour.pluie_mm > 0 && <span className="meteo-jour-pluie">💧 {jour.pluie_mm} mm</span>}
              </div>
            ))}
          </div>
        )}
        <img src={meteoImg} alt="" className="carte-meteo-image" loading="lazy" />
      </section>

      {prevision?.risques?.length > 0 && (
        <>
          <h2 className="titre-section-module">⚠️ Risques détectés ({ville})</h2>
          <div className="liste-alertes">
            {prevision.risques.map((risque, index) => {
              const niveau = NIVEAUX[risque.niveau] || NIVEAUX.info
              return (
                <article key={index} className={`carte-alerte alerte-${niveau.carte}`}>
                  <span className="carte-alerte-icone" aria-hidden="true">⛈️</span>
                  <div className="carte-alerte-corps">
                    <div className="carte-alerte-entete">
                      <h3>{risque.titre}</h3>
                      <span className={`etiquette-statut etiquette-${niveau.etiquette}`}>{niveau.libelle}</span>
                    </div>
                    <p className="carte-alerte-conseil">💡 {risque.message}</p>
                  </div>
                </article>
              )
            })}
          </div>
        </>
      )}

      <h2 className="titre-section-module">🔔 Mes alertes {nonLues > 0 && `(${nonLues} non lue${nonLues > 1 ? 's' : ''})`}</h2>

      <div className="barre-actions-alertes">
        <button
          type="button"
          className="btn btn-secondaire btn-petit"
          disabled={occupe}
          onClick={() =>
            action(alertes.generer, (r) => `${r.creees} nouvelle(s) alerte(s) générée(s).`)
          }
        >
          Actualiser mes alertes
        </button>
        <button
          type="button"
          className="btn btn-secondaire btn-petit"
          disabled={occupe || nonLues === 0}
          onClick={() => action(alertes.toutMarquerLu, 'Toutes les alertes sont marquées comme lues.')}
        >
          Tout marquer comme lu
        </button>
      </div>

      {info && <Message type="succes">{info}</Message>}
      {erreur && <Message type="erreur">{erreur}</Message>}

      {chargement ? (
        <Spinner taille={32} />
      ) : liste.length === 0 ? (
        <div className="etat-vide">
          <strong>Aucune alerte pour le moment</strong>
          <p>Cliquez sur « Actualiser mes alertes » pour vérifier la météo, vos cultures et vos soins.</p>
        </div>
      ) : (
        <div className="liste-alertes">
          {liste.map((alerte) => {
            const niveau = NIVEAUX[alerte.niveau] || NIVEAUX.info
            return (
              <article
                key={alerte.id}
                className={`carte-alerte alerte-${niveau.carte} ${alerte.lue ? '' : 'alerte-non-lue'}`}
              >
                <span className="carte-alerte-icone" aria-hidden="true">{ICONES_TYPE[alerte.type] || '🔔'}</span>
                <div className="carte-alerte-corps">
                  <div className="carte-alerte-entete">
                    <h3>{alerte.titre}</h3>
                    <span className={`etiquette-statut etiquette-${niveau.etiquette}`}>{niveau.libelle}</span>
                  </div>
                  <p className="carte-alerte-meta">
                    {alerte.zone && <>📍 {alerte.zone} · </>}🕒 {formaterDateHeure(alerte.date_creation)}
                  </p>
                  <p className="carte-alerte-conseil">💡 {alerte.message}</p>
                  {!alerte.lue && (
                    <div className="carte-actions">
                      <button
                        type="button"
                        className="btn btn-secondaire btn-petit"
                        disabled={occupe}
                        onClick={() => action(() => alertes.marquerLue(alerte.id), '')}
                      >
                        Marquer comme lue
                      </button>
                    </div>
                  )}
                </div>
              </article>
            )
          })}
        </div>
      )}
    </div>
  )
}
