import { useEffect, useState } from 'react'
import imgMil from '../assets/img/culture-mil.jpg'
import imgArachide from '../assets/img/culture-arachide.jpg'
import imgMais from '../assets/img/culture-mais.jpg'
import imgCultures from '../assets/img/cultures.jpg'
import BandeauApercu from '../components/common/BandeauApercu'
import Message from '../components/common/Message'
import Spinner from '../components/common/Spinner'
import ModalFormulaire from '../components/common/ModalFormulaire'
import { messageErreur, parcelles } from '../api/modulesService'

/* MODULE CULTURES — données réelles (API /api/parcelles/) */

const STATUTS = [
  { valeur: 'preparation', libelle: 'En préparation', classe: 'semis', base: 5 },
  { valeur: 'semee', libelle: 'Semée', classe: 'semis', base: 20 },
  { valeur: 'croissance', libelle: 'En croissance', classe: 'croissance', base: 60 },
  { valeur: 'recoltee', libelle: 'Récoltée', classe: 'recolte', base: 100 },
]

function visuelCulture(nom = '') {
  const n = nom.toLowerCase()
  if (n.includes('mil')) return { image: imgMil, emoji: '🌾' }
  if (n.includes('arachide')) return { image: imgArachide, emoji: '🥜' }
  if (n.includes('maïs') || n.includes('mais')) return { image: imgMais, emoji: '🌽' }
  return { image: imgCultures, emoji: '🌱' }
}

function formaterDate(iso) {
  if (!iso) return 'Non renseignée'
  return new Date(`${iso}T00:00:00`).toLocaleDateString('fr-FR', {
    day: 'numeric', month: 'long', year: 'numeric',
  })
}

function progression(parcelle) {
  const statut = STATUTS.find((s) => s.valeur === parcelle.statut)
  if (parcelle.statut === 'recoltee') return 100
  const { date_semis: semis, date_recolte_prevue: recolte } = parcelle
  if (semis && recolte) {
    const debut = new Date(semis).getTime()
    const fin = new Date(recolte).getTime()
    if (fin > debut) {
      const pct = ((Date.now() - debut) / (fin - debut)) * 100
      return Math.max(0, Math.min(99, Math.round(pct)))
    }
  }
  return statut?.base ?? 0
}

function rappelRecolte(parcelle) {
  if (parcelle.statut === 'recoltee' || !parcelle.date_recolte_prevue) return null
  const jours = Math.ceil(
    (new Date(`${parcelle.date_recolte_prevue}T00:00:00`) - new Date().setHours(0, 0, 0, 0)) / 86400000,
  )
  if (jours < 0) return `Récolte prévue dépassée de ${-jours} jour(s)`
  if (jours === 0) return "Récolte prévue aujourd'hui"
  return `Récolte prévue dans ${jours} jour(s)`
}

const CHAMPS = [
  { nom: 'nom', label: 'Nom de la parcelle', requis: true },
  { nom: 'culture', label: 'Culture (mil, arachide…)', requis: true },
  { nom: 'superficie', label: 'Superficie (hectares)', type: 'number', requis: true, min: 0 },
  { nom: 'localisation', label: 'Localisation' },
  { nom: 'date_semis', label: 'Date de semis', type: 'date' },
  { nom: 'date_recolte_prevue', label: 'Récolte prévue', type: 'date' },
  {
    nom: 'statut',
    label: 'Statut',
    type: 'select',
    options: STATUTS.map((s) => ({ valeur: s.valeur, libelle: s.libelle })),
  },
  { nom: 'notes', label: 'Notes', type: 'textarea', pleineLargeur: true },
]

const VIDE = {
  nom: '', culture: '', superficie: '', localisation: '',
  date_semis: '', date_recolte_prevue: '', statut: 'preparation', notes: '',
}

export default function Cultures() {
  const [liste, setListe] = useState([])
  const [chargement, setChargement] = useState(true)
  const [erreur, setErreur] = useState('')
  const [filtre, setFiltre] = useState('Toutes')
  const [formulaire, setFormulaire] = useState(null) // null | 'nouvelle' | parcelle

  const [version, setVersion] = useState(0)
  const recharger = () => setVersion((v) => v + 1)

  useEffect(() => {
    let ignore = false
    ;(async () => {
      try {
        const donnees = await parcelles.lister()
        if (ignore) return
        setListe(donnees)
        setErreur('')
      } catch (e) {
        if (ignore) return
        setErreur(messageErreur(e, 'Impossible de charger les parcelles.'))
      } finally {
        if (!ignore) setChargement(false)
      }
    })()
    return () => {
      ignore = true
    }
  }, [version])

  async function enregistrer(valeurs) {
    const donnees = { ...valeurs }
    // les dates vides doivent être envoyées à null, pas à ''
    donnees.date_semis = donnees.date_semis || null
    donnees.date_recolte_prevue = donnees.date_recolte_prevue || null
    try {
      if (formulaire === 'nouvelle') await parcelles.creer(donnees)
      else await parcelles.modifier(formulaire.id, donnees)
    } catch (e) {
      throw new Error(messageErreur(e), { cause: e })
    }
    setFormulaire(null)
    recharger()
  }

  async function supprimer(parcelle) {
    if (!window.confirm(`Supprimer la parcelle « ${parcelle.nom} » ?`)) return
    try {
      await parcelles.supprimer(parcelle.id)
      recharger()
    } catch (e) {
      setErreur(messageErreur(e))
    }
  }

  const culturesUniques = ['Toutes', ...new Set(liste.map((p) => p.culture))]
  const affichees = filtre === 'Toutes' ? liste : liste.filter((p) => p.culture === filtre)
  const surfaceTotale = liste.reduce((total, p) => total + Number(p.superficie), 0)
  const enCours = liste.filter((p) => p.statut !== 'recoltee')
  const prochaine = enCours
    .filter((p) => p.date_recolte_prevue)
    .map((p) => p.date_recolte_prevue)
    .sort()[0]

  return (
    <div className="page-module">
      <BandeauApercu
        icone="🌾"
        titre="Suivi des cultures"
        texte="Suivez vos parcelles de la semence à la récolte, anticipez chaque étape."
      />

      {erreur && <Message type="erreur">{erreur}</Message>}

      <div className="stats-module">
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">{liste.length}</span>
          <span className="stat-pilule-libelle">Parcelles suivies</span>
        </div>
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">{surfaceTotale.toFixed(1)} ha</span>
          <span className="stat-pilule-libelle">Surface totale</span>
        </div>
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">
            {prochaine
              ? new Date(`${prochaine}T00:00:00`).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short' })
              : '—'}
          </span>
          <span className="stat-pilule-libelle">Prochaine récolte</span>
        </div>
        <div className="stat-pilule">
          <span className="stat-pilule-valeur">{enCours.length}</span>
          <span className="stat-pilule-libelle">Cultures en cours</span>
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
        <button
          type="button"
          className="btn btn-primaire btn-petit puce-action"
          onClick={() => setFormulaire('nouvelle')}
        >
          + Nouvelle parcelle
        </button>
      </div>

      {chargement ? (
        <Spinner taille={32} />
      ) : affichees.length === 0 ? (
        <div className="etat-vide">
          <strong>Aucune parcelle pour le moment</strong>
          <p>Cliquez sur « + Nouvelle parcelle » pour ajouter votre première culture.</p>
        </div>
      ) : (
        <div className="grille-parcelles">
          {affichees.map((parcelle) => {
            const statut = STATUTS.find((s) => s.valeur === parcelle.statut) || STATUTS[0]
            const visuel = visuelCulture(parcelle.culture)
            const pct = progression(parcelle)
            const rappel = rappelRecolte(parcelle)
            return (
              <article key={parcelle.id} className="carte-parcelle">
                <div className="carte-parcelle-visuel">
                  <img src={visuel.image} alt={parcelle.culture} loading="lazy" />
                  <span className="carte-parcelle-emoji" aria-hidden="true">{visuel.emoji}</span>
                  <span className={`etiquette-statut etiquette-${statut.classe}`}>{statut.libelle}</span>
                </div>
                <div className="carte-parcelle-corps">
                  <h3>{parcelle.nom} · {parcelle.culture}</h3>
                  <div className="carte-parcelle-meta">
                    <span>📐 {parcelle.superficie} ha{parcelle.localisation ? ` · ${parcelle.localisation}` : ''}</span>
                    <span>🌱 Semis : {formaterDate(parcelle.date_semis)}</span>
                    <span>🧺 Récolte : {formaterDate(parcelle.date_recolte_prevue)}</span>
                  </div>
                  <div className="progression">
                    <div className="progression-entete">
                      <span>Avancement</span>
                      <span>{pct}%</span>
                    </div>
                    <div className="progression-piste">
                      <span className="progression-remplissage" style={{ width: `${pct}%` }} />
                    </div>
                  </div>
                  {rappel && <p className="carte-parcelle-rappel">🔔 {rappel}</p>}
                  <div className="carte-actions">
                    <button type="button" className="btn btn-secondaire btn-petit" onClick={() => setFormulaire(parcelle)}>
                      Modifier
                    </button>
                    <button type="button" className="btn btn-danger btn-petit" onClick={() => supprimer(parcelle)}>
                      Supprimer
                    </button>
                  </div>
                </div>
              </article>
            )
          })}
        </div>
      )}

      {formulaire && (
        <ModalFormulaire
          titre={formulaire === 'nouvelle' ? 'Nouvelle parcelle' : 'Modifier la parcelle'}
          champs={CHAMPS}
          valeursInitiales={
            formulaire === 'nouvelle'
              ? VIDE
              : Object.fromEntries(CHAMPS.map((c) => [c.nom, formulaire[c.nom] ?? '']))
          }
          onSubmit={enregistrer}
          onFermer={() => setFormulaire(null)}
        />
      )}
    </div>
  )
}
