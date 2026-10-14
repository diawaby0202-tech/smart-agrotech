import { Link } from 'react-router-dom'
import heroImg from '../assets/img/hero.jpg'
import culturesImg from '../assets/img/cultures.jpg'
import elevageImg from '../assets/img/elevage.jpg'
import meteoImg from '../assets/img/meteo.jpg'
import marcheImg from '../assets/img/marche.jpg'
import producteurImg from '../assets/img/producteur.jpg'
import acheteurImg from '../assets/img/acheteur.jpg'
import structuresImg from '../assets/img/structures.jpg'

const modules = [
  {
    icone: '🌾',
    titre: 'Cultures & récoltes',
    texte:
      'Enregistrez vos parcelles, suivez leur évolution (semis, croissance, récolte) et anticipez vos récoltes.',
    lien: '/cultures',
    image: culturesImg,
  },
  {
    icone: '🐄',
    titre: 'Élevage',
    texte:
      'Tenez à jour la fiche de chaque animal, consignez les soins et recevez des rappels de vaccination.',
    lien: '/elevage',
    image: elevageImg,
  },
  {
    icone: '⛅',
    titre: 'Alertes météo',
    texte:
      'Consultez les prévisions de votre zone et soyez alerté des risques climatiques en amont.',
    lien: '/alertes',
    image: meteoImg,
  },
  {
    icone: '🛒',
    titre: 'Marché agricole',
    texte:
      'Publiez vos annonces, trouvez des produits locaux et contactez directement les vendeurs.',
    lien: '/marche',
    image: marcheImg,
  },
]

const statistiques = [
  { valeur: '4', libelle: 'Modules intégrés' },
  { valeur: '3', libelle: 'Profils utilisateurs' },
  { valeur: '24/7', libelle: 'Accès web & mobile' },
  { valeur: '100%', libelle: 'Adapté au terrain' },
]

const publics = [
  {
    icone: '🧑‍🌾',
    titre: 'Agriculteurs & éleveurs',
    texte: 'Suivi des parcelles et du bétail, rappels d’intervention et publication d’annonces.',
    image: producteurImg,
  },
  {
    icone: '🛒',
    titre: 'Acheteurs',
    texte: 'Recherche de produits locaux et mise en relation directe avec les producteurs.',
    image: acheteurImg,
  },
  {
    icone: '🏛️',
    titre: 'Structures d’appui',
    texte: 'ONG et services techniques : supervision et suivi des activités de leur zone.',
    image: structuresImg,
  },
]

export default function Accueil() {
  return (
    <div className="page-accueil">
      <section className="accueil-hero apparait">
        <div className="accueil-hero-texte">
          <p className="etiquette">
            <span aria-hidden="true">🌱</span> La plateforme de l’agriculture sénégalaise
          </p>
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
          <div className="accueil-hero-photo">
            <img src={heroImg} alt="Agriculteur dans un champ au Sénégal" loading="eager" />
            <div className="accueil-hero-badge">
              <span className="accueil-hero-badge-icone" aria-hidden="true">🌾</span>
              <div>
                <strong>Suivi en temps réel</strong>
                <span>Parcelles, bétail, météo & marché</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="bandeau-stats">
        {statistiques.map((stat) => (
          <div className="stat-item" key={stat.libelle}>
            <div className="stat-valeur">{stat.valeur}</div>
            <div className="stat-libelle">{stat.libelle}</div>
          </div>
        ))}
      </section>

      <section className="accueil-modules">
        <div className="section-titre">
          <h2>Une plateforme, quatre modules</h2>
          <p>
            Tout ce dont vous avez besoin pour piloter votre exploitation agricole au quotidien,
            réuni dans une interface simple et accessible.
          </p>
        </div>
        <div className="grille-modules">
          {modules.map((module) => (
            <Link to={module.lien} key={module.titre} className="carte-module">
              <div className="carte-module-media">
                <img src={module.image} alt={module.titre} loading="lazy" />
                <span className="carte-module-icone" aria-hidden="true">{module.icone}</span>
              </div>
              <div className="carte-module-corps">
                <h3>{module.titre}</h3>
                <p>{module.texte}</p>
                <span className="carte-module-lien">Découvrir →</span>
              </div>
            </Link>
          ))}
        </div>
      </section>

      <section className="accueil-publics">
        <div className="section-titre">
          <h2>Pour qui ?</h2>
          <p>
            Une solution pensée pour toute la chaîne agricole sénégalaise, du producteur à
            l’acheteur.
          </p>
        </div>
        <div className="grille-publics">
          {publics.map((public_) => (
            <div className="carte-public" key={public_.titre}>
              <div className="carte-public-media">
                <img src={public_.image} alt={public_.titre} loading="lazy" />
                <span className="carte-public-icone" aria-hidden="true">{public_.icone}</span>
              </div>
              <div className="carte-public-corps">
                <h3>{public_.titre}</h3>
                <p>{public_.texte}</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      <section className="accueil-cta">
        <div className="accueil-cta-bloc">
          <h2>Prêt à moderniser votre exploitation ?</h2>
          <p>
            Rejoignez Smart AgroTech Sénégal et accédez à tous vos outils de suivi agricole,
            où que vous soyez, depuis votre téléphone ou votre ordinateur.
          </p>
          <div className="accueil-cta-actions">
            <Link to="/inscription" className="btn btn-or btn-grand">
              Commencer maintenant
            </Link>
            <Link to="/marche" className="btn btn-contour btn-grand">
              Explorer le marché
            </Link>
          </div>
        </div>
      </section>
    </div>
  )
}

