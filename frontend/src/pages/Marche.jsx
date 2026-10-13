import { useState } from 'react'
import marcheImg from '../assets/img/marche.jpg'
import BandeauApercu from '../components/common/BandeauApercu'

/* ============================================================
   MODULE MARCHE — maquette de démonstration
   Annonces d’exemple (100 % fictives) pour la soutenance.
   ============================================================ */

const annonces = [
  {
    id: 1,
    titre: 'Mil en grain — 500 kg',
    prix: '275 000 FCFA',
    unite: 'le sac de 50 kg',
    zone: 'Kaolack',
    vendeur: 'Coopérative Thiossane',
    note: 4.8,
    categorie: 'Céréales',
    emoji: '🌾',
  },
  {
    id: 2,
    titre: 'Tomates fraîches — 200 kg',
    prix: '60 000 FCFA',
    unite: 'le plateau',
    zone: 'Niayes, Dakar',
    vendeur: 'Ferme Dieng',
    note: 4.6,
    categorie: 'Maraîchage',
    emoji: '🍅',
  },
  {
    id: 3,
    titre: 'Bœuf de race — 3 têtes',
    prix: '900 000 FCFA',
    unite: 'par tête',
    zone: 'Louga',
    vendeur: 'Élevage Wane',
    note: 4.9,
    categorie: 'Élevage',
    emoji: '🐄',
  },
  {
    id: 4,
    titre: 'Oignons rouges — 120 kg',
    prix: '45 000 FCFA',
    unite: 'le sac',
    zone: 'Podor',
    vendeur: 'Groupement Faye',
    note: 4.4,
    categorie: 'Maraîchage',
    emoji: '🧅',
  },
]

const categories = ['Tout', 'Céréales', 'Maraîchage', 'Élevage']

export default function Marche() {
  const [categorieActive, setCategorieActive] = useState('Tout')
  const annoncesAffichees =
    categorieActive === 'Tout' ? annonces : annonces.filter((a) => a.categorie === categorieActive)

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
          placeholder="Rechercher un produit, une zone…"
          aria-label="Rechercher une annonce"
          disabled
        />
        <span className="barre-recherche-icone" aria-hidden="true">🔍</span>
        <button type="button" className="btn btn-primaire btn-petit puce-action" disabled>
          + Vendre
        </button>
      </div>

      <div className="filtres-module">
        {categories.map((categorie) => (
          <button
            key={categorie}
            type="button"
            className={`puce-filtre ${categorieActive === categorie ? 'actif' : ''}`}
            onClick={() => setCategorieActive(categorie)}
          >
            {categorie}
          </button>
        ))}
      </div>

      <div className="grille-annonces">
        {annoncesAffichees.map((annonce) => (
          <article key={annonce.id} className="carte-annonce">
            <div className="carte-annonce-visuel">
              <img src={marcheImg} alt="" loading="lazy" />
              <span className="carte-annonce-emoji" aria-hidden="true">{annonce.emoji}</span>
              <span className="carte-annonce-zone">📍 {annonce.zone}</span>
            </div>
            <div className="carte-annonce-corps">
              <span className="carte-annonce-cat">{annonce.categorie}</span>
              <h3>{annonce.titre}</h3>
              <p className="carte-annonce-prix">
                {annonce.prix} <span>/ {annonce.unite}</span>
              </p>
              <div className="carte-annonce-pied">
                <span className="carte-annonce-vendeur">👤 {annonce.vendeur}</span>
                <span className="carte-annonce-note">★ {annonce.note}</span>
              </div>
              <button type="button" className="btn btn-secondaire btn-petit btn-plein" disabled>
                Contacter le vendeur
              </button>
            </div>
          </article>
        ))}
      </div>
    </div>
  )
}