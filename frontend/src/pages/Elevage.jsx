import { useEffect, useState } from 'react'
import imgBovin from '../assets/img/elevage-bovin.jpg'
import imgCaprin from '../assets/img/elevage-caprin.jpg'
import imgOvin from '../assets/img/elevage-ovin.jpg'
import imgElevage from '../assets/img/elevage.jpg'
import BandeauApercu from '../components/common/BandeauApercu'
import Message from '../components/common/Message'
import Spinner from '../components/common/Spinner'
import ModalFormulaire from '../components/common/ModalFormulaire'
import { animaux, messageErreur, suivis } from '../api/modulesService'

/* MODULE ÉLEVAGE — données réelles (API /api/animaux/ et /api/suivis-sanitaires/) */

function visuelEspece(espece = '') {
  const e = espece.toLowerCase()
  if (e.includes('bov') || e.includes('vache') || e.includes('boeuf') || e.includes('bœuf'))
    return { image: imgBovin, emoji: '🐄' }
  if (e.includes('cap') || e.includes('chèvre') || e.includes('chevre'))
    return { image: imgCaprin, emoji: '🐐' }
  if (e.includes('ovin') || e.includes('mouton') || e.includes('brebis') || e.includes('bélier'))
    return { image: imgOvin, emoji: '🐏' }
  return { image: imgElevage, emoji: '🐾' }
}

const TYPES_SUIVI = [
  { valeur: 'vaccination', libelle: 'Vaccination' },
  { valeur: 'traitement', libelle: 'Traitement' },
  { valeur: 'visite', libelle: 'Visite vétérinaire' },
]
const libelleType = Object.fromEntries(TYPES_SUIVI.map((t) => [t.valeur, t.libelle]))
const libelleEtat = { bon: 'Bonne santé', attention: 'À surveiller', critique: 'Urgent' }
const classeEtat = { bon: 'croissance', attention: 'semis', critique: 'floraison' }

function aujourdhui() {
  return new Date().toISOString().slice(0, 10)
}

function formaterDate(iso) {
  return new Date(`${iso}T00:00:00`).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long' })
}

function ecartJours(iso) {
  return Math.round((new Date(`${iso}T00:00:00`) - new Date(`${aujourdhui()}T00:00:00`)) / 86400000)
}

function ageAnimal(naissance) {
  if (!naissance) return 'Âge non renseigné'
  const mois = Math.floor((Date.now() - new Date(naissance)) / (30.44 * 86400000))
  if (mois < 0) return 'Âge non renseigné'
  if (mois < 12) return `${mois} mois`
  const ans = Math.floor(mois / 12)
  return `${ans} an${ans > 1 ? 's' : ''}`
}

const CHAMPS_ANIMAL = [
  { nom: 'espece', label: 'Espèce (bovin, caprin, ovin…)', requis: true },
  { nom: 'race', label: 'Race' },
  { nom: 'identifiant', label: 'Identifiant / nom du lot' },
  { nom: 'effectif', label: 'Effectif (1 = animal seul)', type: 'number', min: 1, requis: true },
  { nom: 'date_naissance', label: 'Date de naissance', type: 'date' },
  { nom: 'notes', label: 'Notes', type: 'textarea', pleineLargeur: true },
]
const CHAMPS_SUIVI = [
  {
    nom: 'type', label: 'Type de soin', type: 'select',
    options: TYPES_SUIVI,
  },
  { nom: 'date', label: 'Date du soin', type: 'date', requis: true },
  { nom: 'prochaine_echeance', label: 'Prochaine échéance', type: 'date' },
  { nom: 'description', label: 'Description (produit, dose…)', type: 'textarea', pleineLargeur: true },
]

export default function Elevage() {
  const [liste, setListe] = useState([])
  const [soins, setSoins] = useState([])
  const [chargement, setChargement] = useState(true)
  const [erreur, setErreur] = useState('')
  const [especeActive, setEspeceActive] = useState('Tous')
  const [formAnimal, setFormAnimal] = useState(null) // null | 'nouveau' | animal
  const [formSoin, setFormSoin] = useState(null) // null | animal

  const [version, setVersion] = useState(0)
  const recharger = () => setVersion((v) => v + 1)

  useEffect(() => {
    let ignore = false
    ;(async () => {
      try {
        const [a, s] = await Promise.all([animaux.lister(), suivis.lister()])
        if (ignore) return
        setListe(a)
        setSoins(s)
        setErreur('')
      } catch (e) {
        if (ignore) return
        setErreur(messageErreur(e, "Impossible de charger l'élevage."))
      } finally {
        if (!ignore) setChargement(false)
      }
    })()
    return () => {
      ignore = true
    }
  }, [version])

  /** Prochain soin à venir (ou en retard) d'un animal, d'après ses suivis. */
  function prochainSoin(animal) {
    const aVenir = soins
      .filter((s) => s.animal === animal.id && s.prochaine_echeance)
      .sort((a, b) => a.prochaine_echeance.localeCompare(b.prochaine_echeance))
    // on ignore une échéance déjà couverte par un soin plus récent du même type
    return aVenir.find((s) => {
      const plusRecent = soins.some(
        (autre) => autre.animal === animal.id && autre.type === s.type && autre.date > s.date,
      )
      return !plusRecent
    })
  }

  function etatAnimal(animal) {
    const soin = prochainSoin(animal)
    if (!soin) return 'bon'
    const ecart = ecartJours(soin.prochaine_echeance)
    if (ecart < 0) return 'critique'
    if (ecart <= 7) return 'attention'
    return 'bon'
  }

  async function enregistrerAnimal(valeurs) {
    const donnees = { ...valeurs, date_naissance: valeurs.date_naissance || null }
    try {
      if (formAnimal === 'nouveau') await animaux.creer(donnees)
      else await animaux.modifier(formAnimal.id, donnees)
    } catch (e) {
      throw new Error(messageErreur(e), { cause: e })
    }
    setFormAnimal(null)
    recharger()
  }

  async function enregistrerSoin(valeurs) {
    try {
      await suivis.creer({
        ...valeurs,
        animal: formSoin.id,
        prochaine_echeance: valeurs.prochaine_echeance || null,
      })
    } catch (e) {
      throw new Error(messageErreur(e), { cause: e })
    }
    setFormSoin(null)
    recharger()
  }

  async function supprimer(animal) {
    if (!window.confirm(`Supprimer la fiche « ${animal.identifiant || animal.espece} » et ses soins ?`)) return
    try {
      await animaux.supprimer(animal.id)
      recharger()
    } catch (e) {
      setErreur(messageErreur(e))
    }
  }

  const especes = ['Tous', ...new Set(liste.map((a) => a.espece))]
  const affiches = especeActive === 'Tous' ? liste : liste.filter((a) => a.espece === especeActive)
  const totalTetes = liste.reduce((total, a) => total + a.effectif, 0)
  const soinsProches = liste.filter((a) => etatAnimal(a) !== 'bon').length

  return (
    <div className="page-module">
      <BandeauApercu
        icone="🐄"
        titre="Gestion de l’élevage"
        texte="Un troupeau en bonne santé, suivi au plus près : soins, vaccins, alertes."
      />

      {erreur && <Message type="erreur">{erreur}</Message>}

      <div className="stats-module">
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">{liste.length}</span>
          <span className="stat-pilule-libelle">Fiches suivies</span>
        </div>
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">{totalTetes}</span>
          <span className="stat-pilule-libelle">Têtes au total</span>
        </div>
        <div className="stat-pilule stat-alerte">
          <span className="stat-pilule-valeur">{soinsProches}</span>
          <span className="stat-pilule-libelle">Soin à prévoir (7 j)</span>
        </div>
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">{soins.length}</span>
          <span className="stat-pilule-libelle">Soins enregistrés</span>
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
        <button
          type="button"
          className="btn btn-primaire btn-petit puce-action"
          onClick={() => setFormAnimal('nouveau')}
        >
          + Ajouter un animal
        </button>
      </div>

      {chargement ? (
        <Spinner taille={32} />
      ) : affiches.length === 0 ? (
        <div className="etat-vide">
          <strong>Aucun animal enregistré</strong>
          <p>Cliquez sur « + Ajouter un animal » pour créer une fiche (animal seul ou lot).</p>
        </div>
      ) : (
        <div className="grille-parcelles">
          {affiches.map((animal) => {
            const visuel = visuelEspece(animal.espece)
            const etat = etatAnimal(animal)
            const soin = prochainSoin(animal)
            const ecart = soin ? ecartJours(soin.prochaine_echeance) : null
            return (
              <article key={animal.id} className="carte-parcelle">
                <div className="carte-parcelle-visuel">
                  <img src={visuel.image} alt={animal.espece} loading="lazy" />
                  <span className="carte-parcelle-emoji" aria-hidden="true">{visuel.emoji}</span>
                  <span className={`etiquette-statut etiquette-${classeEtat[etat]}`}>{libelleEtat[etat]}</span>
                </div>
                <div className="carte-parcelle-corps">
                  <h3>{animal.identifiant || animal.espece}{animal.effectif > 1 ? ` (${animal.effectif} têtes)` : ''}</h3>
                  <div className="carte-parcelle-meta">
                    <span>🏷️ {animal.espece}{animal.race ? ` · ${animal.race}` : ''}</span>
                    <span>🎂 {ageAnimal(animal.date_naissance)}</span>
                    <span>💚 {libelleEtat[etat]}</span>
                  </div>
                  {soin ? (
                    <p className="carte-parcelle-rappel">
                      🔔 {libelleType[soin.type]} — {formaterDate(soin.prochaine_echeance)}
                      {ecart < 0 ? ` (en retard de ${-ecart} j)` : ecart === 0 ? " (aujourd'hui)" : ` (dans ${ecart} j)`}
                    </p>
                  ) : (
                    <p className="carte-parcelle-rappel">✅ Aucun soin planifié</p>
                  )}
                  <div className="carte-actions">
                    <button type="button" className="btn btn-secondaire btn-petit" onClick={() => setFormSoin(animal)}>
                      + Soin
                    </button>
                    <button type="button" className="btn btn-secondaire btn-petit" onClick={() => setFormAnimal(animal)}>
                      Modifier
                    </button>
                    <button type="button" className="btn btn-danger btn-petit" onClick={() => supprimer(animal)}>
                      Supprimer
                    </button>
                  </div>
                </div>
              </article>
            )
          })}
        </div>
      )}

      {formAnimal && (
        <ModalFormulaire
          titre={formAnimal === 'nouveau' ? 'Ajouter un animal' : "Modifier l'animal"}
          champs={CHAMPS_ANIMAL}
          valeursInitiales={
            formAnimal === 'nouveau'
              ? { espece: '', race: '', identifiant: '', effectif: 1, date_naissance: '', notes: '' }
              : Object.fromEntries(CHAMPS_ANIMAL.map((c) => [c.nom, formAnimal[c.nom] ?? '']))
          }
          onSubmit={enregistrerAnimal}
          onFermer={() => setFormAnimal(null)}
        />
      )}

      {formSoin && (
        <ModalFormulaire
          titre={`Nouveau soin — ${formSoin.identifiant || formSoin.espece}`}
          champs={CHAMPS_SUIVI}
          valeursInitiales={{ type: 'vaccination', date: aujourdhui(), prochaine_echeance: '', description: '' }}
          libelleBouton="Enregistrer le soin"
          onSubmit={enregistrerSoin}
          onFermer={() => setFormSoin(null)}
        />
      )}
    </div>
  )
}
