import { Link } from 'react-router-dom'
import heroImg from '../assets/hero.png'

const modules = [
  {
    icone: '🌾',
    titre: 'Cultures & récoltes',
    texte:
      'Enregistrez vos parcelles, suivez l’évolution de vos cultures (semis, croissance, récolte) et consultez un calendrier prévisionnel de récolte.',
    lien: '/cultures',
  },
  {
    icone: '🐄',
    titre: 'Élevage',
    texte:
      'Tenez à jour la fiche de chaque animal ou lot, consignez les soins vétérinaires et recevez des rappels de vaccination.',
    lien: '/elevage',
  },
  {
    icone: '⛅',
    titre: 'Alertes météo',
    texte:
      'Consultez les prévisions de votre zone et soyez alerté des risques climatiques : sécheresse, fortes pluies, vagues de chaleur.',
    lien: '/alertes',
  },
  {
    icone: '🛒',
    titre: 'Marché agricole',
    texte:
      'Publiez vos annonces de vente, recherchez des produits par catégorie, zone ou prix, et contactez directement les vendeurs.',
    lien: '/marche',
  },
]

export default function Accueil() {
  return (
    <div className="page-accueil">
      <section className="accueil-hero">
        <div className="accueil-hero-texte">
          <p className="etiquette">Plateforme numérique pour l’agriculture sénégalaise</p>
          <h1>
            Gérez vos cultures, votre bétail et vos ventes, <span>depuis un seul endroit</span>.
          </h1>
          <p className="accueil-sous-titre">
            Smart AgroTech Sénégal aide les agriculteurs, éleveurs et acheteurs à mieux suivre
            leurs activités, anticiper les risques climatiques et accéder à un marché en ligne local.
          </p>
          <div className="accueil-actions">
            <Link to="/inscription" className="btn btn-primaire btn-grand">
              Créer un compte gratuit
            </Link>
            <Link to="/connexion" className="btn btn-secondaire btn-grand">
              J’ai déjà un compte
            </Link>
          </div>
        </div>
        <div className="accueil-hero-image">
          <img src={heroImg} alt="Illustration Smart AgroTech" />
        </div>
      </section>

      <section className="accueil-modules">
        <h2>Une plateforme, quatre modules</h2>
        <div className="grille-modules">
          {modules.map((module) => (
            <Link to={module.lien} key={module.titre} className="carte-module">
              <span className="carte-module-icone" aria-hidden="true">{module.icone}</span>
              <h3>{module.titre}</h3>
              <p>{module.texte}</p>
            </Link>
          ))}
        </div>
      </section>

      <section className="accueil-publics">
        <h2>Pour qui ?</h2>
        <div className="grille-publics">
          <div className="carte-public">
            <h3>🧑‍🌾 Agriculteurs & éleveurs</h3>
            <p>Suivi des parcelles et du bétail, rappels d’intervention et publication d’annonces.</p>
          </div>
          <div className="carte-public">
            <h3>🛒 Acheteurs</h3>
            <p>Recherche de produits locaux et mise en relation directe avec les producteurs.</p>
          </div>
          <div className="carte-public">
            <h3>👀 Visiteurs</h3>
            <p>Consultation des informations publiques et des annonces ouvertes, sans compte.</p>
          </div>
        </div>
      </section>
    </div>
  )
}
