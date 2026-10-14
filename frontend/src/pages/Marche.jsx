import { useEffect, useState } from 'react'
import imgMil from '../assets/img/culture-mil.jpg'
import imgTomates from '../assets/img/marche-tomates.jpg'
import imgBoeuf from '../assets/img/elevage-bovin.jpg'
import imgOignons from '../assets/img/marche-oignons.jpg'
import imgMarche from '../assets/img/marche.jpg'
import '../styles-modules.css'
import BandeauApercu from '../components/common/BandeauApercu'
import Message from '../components/common/Message'
import Spinner from '../components/common/Spinner'
import ModalFormulaire from '../components/common/ModalFormulaire'
import { useAuth } from '../context/AuthContext'
import { annonces, messageErreur } from '../api/modulesService'

/* MODULE MARCHÉ — données réelles (API /api/annonces/) */

const CATEGORIES = [
  { valeur: 'cereales', libelle: 'Céréales', emoji: '🌾', image: imgMil },
  { valeur: 'legumes', libelle: 'Légumes', emoji: '🍅', image: imgTomates },
  { valeur: 'fruits', libelle: 'Fruits', emoji: '🍉', image: imgOignons },
  { valeur: 'betail', libelle: 'Bétail', emoji: '🐄', image: imgBoeuf },
  { valeur: 'intrants', libelle: 'Intrants / matériel', emoji: '🧰', image: imgMarche },
  { valeur: 'autre', libelle: 'Autre', emoji: '📦', image: imgMarche },
]
const parCategorie = Object.fromEntries(CATEGORIES.map((c) => [c.valeur, c]))
const formatPrix = new Intl.NumberFormat('fr-FR')

const CHAMPS = [
  { nom: 'titre', label: "Titre de l'annonce", requis: true, pleineLargeur: true },
  {
    nom: 'categorie', label: 'Catégorie', type: 'select',
    options: CATEGORIES.map((c) => ({ valeur: c.valeur, libelle: c.libelle })),
  },
  { nom: 'prix', label: 'Prix (FCFA)', type: 'number', min: 0, requis: true },
  { nom: 'quantite', label: 'Quantité (ex. 50 kg, 3 têtes)' },
  { nom: 'zone', label: 'Zone / ville' },
  { nom: 'image', label: 'Photo (5 Mo maximum)', type: 'file', pleineLargeur: true },
  { nom: 'description', label: 'Description', type: 'textarea', pleineLargeur: true },
]

export default function Marche() {
  const { utilisateur } = useAuth()
  const peutVendre = utilisateur?.role === 'producteur' || utilisateur?.role === 'admin'

  const [liste, setListe] = useState([])
  const [chargement, setChargement] = useState(true)
  const [erreur, setErreur] = useState('')
  const [recherche, setRecherche] = useState('')
  const [rechercheEnvoyee, setRechercheEnvoyee] = useState('')
  const [categorie, setCategorie] = useState('')
  const [mesAnnonces, setMesAnnonces] = useState(false)
  const [formulaire, setFormulaire] = useState(null) // null | 'nouvelle' | annonce
  const [telephoneVisible, setTelephoneVisible] = useState(null)

  // petite attente avant d'interroger l'API pendant la frappe
  useEffect(() => {
    const minuteur = setTimeout(() => setRechercheEnvoyee(recherche.trim()), 350)
    return () => clearTimeout(minuteur)
  }, [recherche])

  const [version, setVersion] = useState(0)
  const recharger = () => setVersion((v) => v + 1)

  useEffect(() => {
    let ignore = false
    ;(async () => {
      try {
        const donnees = await annonces.lister({ q: rechercheEnvoyee, categorie, mesAnnonces })
        if (ignore) return
        setListe(donnees)
        setErreur('')
      } catch (e) {
        if (ignore) return
        setErreur(messageErreur(e, 'Impossible de charger les annonces.'))
      } finally {
        if (!ignore) setChargement(false)
      }
    })()
    return () => {
      ignore = true
    }
  }, [rechercheEnvoyee, categorie, mesAnnonces, version])

  async function enregistrer(valeurs) {
    try {
      if (formulaire === 'nouvelle') {
        const donnees = new FormData()
        Object.entries(valeurs).forEach(([cle, valeur]) => {
          if (valeur !== null && valeur !== '' && valeur !== undefined) donnees.append(cle, valeur)
        })
        await annonces.creer(donnees)
      } else {
        const { image, ...texte } = valeurs
        if (image instanceof File) {
          const donnees = new FormData()
          Object.entries(texte).forEach(([cle, valeur]) => donnees.append(cle, valeur ?? ''))
          donnees.append('image', image)
          await annonces.modifier(formulaire.id, donnees)
        } else {
          await annonces.modifier(formulaire.id, texte)
        }
      }
    } catch (e) {
      throw new Error(messageErreur(e), { cause: e })
    }
    setFormulaire(null)
    recharger()
  }

  async function changerStatut(annonce, statut) {
    try {
      await annonces.modifier(annonce.id, { statut })
      recharger()
    } catch (e) {
      setErreur(messageErreur(e))
    }
  }

  async function supprimer(annonce) {
    if (!window.confirm(`Supprimer l'annonce « ${annonce.titre} » ?`)) return
    try {
      await annonces.supprimer(annonce.id)
      recharger()
    } catch (e) {
      setErreur(messageErreur(e))
    }
  }

  return (
    <div className="page-module">
      <BandeauApercu
        icone="🛒"
        titre="Marché agricole"
        texte="Achetez et vendez des produits locaux, directement entre producteurs et acheteurs."
      />

      <div className="barre-recherche-marche">
        <input
          type="search"
          placeholder="Rechercher un produit…"
          aria-label="Rechercher une annonce"
          value={recherche}
          onChange={(e) => setRecherche(e.target.value)}
        />
        <span className="barre-recherche-icone" aria-hidden="true">🔍</span>
        {peutVendre && (
          <button
            type="button"
            className="btn btn-primaire btn-petit puce-action"
            onClick={() => setFormulaire('nouvelle')}
          >
            + Vendre
          </button>
        )}
      </div>

      <div className="filtres-module">
        <button
          type="button"
          className={`puce-filtre ${categorie === '' ? 'actif' : ''}`}
          onClick={() => setCategorie('')}
        >
          Tout
        </button>
        {CATEGORIES.map((c) => (
          <button
            key={c.valeur}
            type="button"
            className={`puce-filtre ${categorie === c.valeur ? 'actif' : ''}`}
            onClick={() => setCategorie(c.valeur)}
          >
            {c.libelle}
          </button>
        ))}
        {peutVendre && (
          <label className="case-mes-annonces">
            <input
              type="checkbox"
              checked={mesAnnonces}
              onChange={(e) => setMesAnnonces(e.target.checked)}
            />
            Mes annonces
          </label>
        )}
      </div>

      {erreur && <Message type="erreur">{erreur}</Message>}

      {chargement ? (
        <Spinner taille={32} />
      ) : liste.length === 0 ? (
        <div className="etat-vide">
          <strong>Aucune annonce trouvée</strong>
          <p>Modifiez votre recherche ou vos filtres{peutVendre ? ', ou publiez la première annonce.' : '.'}</p>
        </div>
      ) : (
        <div className="grille-annonces">
          {liste.map((annonce) => {
            const cat = parCategorie[annonce.categorie] || parCategorie.autre
            const image = annonce.image || annonce.photo || cat.image
            return (
              <article key={annonce.id} className="carte-annonce">
                <div className="carte-annonce-visuel">
                  <img src={image} alt={annonce.titre} loading="lazy" />
                  <span className="carte-annonce-emoji" aria-hidden="true">{cat.emoji}</span>
                  {annonce.zone && <span className="carte-annonce-zone">📍 {annonce.zone}</span>}
                </div>
                <div className="carte-annonce-corps">
                  <span className="carte-annonce-cat">
                    {cat.libelle}
                    {annonce.statut !== 'disponible' && (
                      <> · <span className="etiquette-vendue">{annonce.statut === 'vendue' ? 'Vendue' : 'Retirée'}</span></>
                    )}
                  </span>
                  <h3>{annonce.titre}</h3>
                  <p className="carte-annonce-prix">{formatPrix.format(annonce.prix)} FCFA</p>
                  {annonce.quantite && <p className="carte-annonce-quantite">Quantité : {annonce.quantite}</p>}
                  <div className="carte-annonce-pied">
                    <span className="carte-annonce-vendeur">👤 {annonce.vendeur_nom}</span>
                  </div>

                  {annonce.est_proprietaire ? (
                    <div className="carte-actions">
                      {annonce.statut === 'disponible' ? (
                        <button type="button" className="btn btn-secondaire btn-petit" onClick={() => changerStatut(annonce, 'vendue')}>
                          Marquer vendue
                        </button>
                      ) : (
                        <button type="button" className="btn btn-secondaire btn-petit" onClick={() => changerStatut(annonce, 'disponible')}>
                          Remettre en vente
                        </button>
                      )}
                      <button type="button" className="btn btn-secondaire btn-petit" onClick={() => setFormulaire(annonce)}>
                        Modifier
                      </button>
                      <button type="button" className="btn btn-danger btn-petit" onClick={() => supprimer(annonce)}>
                        Supprimer
                      </button>
                    </div>
                  ) : telephoneVisible === annonce.id ? (
                    annonce.vendeur_telephone ? (
                      <a className="btn btn-secondaire btn-petit btn-plein" href={`tel:${annonce.vendeur_telephone}`}>
                        📞 {annonce.vendeur_telephone}
                      </a>
                    ) : (
                      <p className="carte-annonce-quantite">Numéro non renseigné par le vendeur.</p>
                    )
                  ) : (
                    <button
                      type="button"
                      className="btn btn-secondaire btn-petit btn-plein"
                      onClick={() => setTelephoneVisible(annonce.id)}
                    >
                      Contacter le vendeur
                    </button>
                  )}
                </div>
              </article>
            )
          })}
        </div>
      )}

      {formulaire && (
        <ModalFormulaire
          titre={formulaire === 'nouvelle' ? 'Publier une annonce' : "Modifier l'annonce"}
          champs={CHAMPS}
          valeursInitiales={
            formulaire === 'nouvelle'
              ? { titre: '', categorie: 'cereales', prix: '', quantite: '', zone: '', image: null, description: '' }
              : {
                  titre: formulaire.titre, categorie: formulaire.categorie, prix: formulaire.prix,
                  quantite: formulaire.quantite, zone: formulaire.zone, image: null,
                  description: formulaire.description,
                }
          }
          libelleBouton={formulaire === 'nouvelle' ? 'Publier' : 'Enregistrer'}
          onSubmit={enregistrer}
          onFermer={() => setFormulaire(null)}
        />
      )}
    </div>
  )
}
