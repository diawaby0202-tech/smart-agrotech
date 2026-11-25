import { Link } from 'react-router-dom'
import heroImg from '../assets/img/hero.jpg'
import culturesImg from '../assets/img/cultures.jpeg'
import elevageImg from '../assets/img/elevage.jpeg'
import meteoImg from '../assets/img/meteo.jpg'
import marcheImg from '../assets/img/marche.jpg'
import producteurImg from '../assets/img/producteur.jpg'
import acheteurImg from '../assets/img/acheteur.jpg'
import structuresImg from '../assets/img/structures.jpg'
import aeImg from '../assets/img/ae.jpeg'
import eImg from '../assets/img/e.jpeg'
import alImg from '../assets/img/al.jpeg'
import pImg from '../assets/img/p.jpeg'
import mImg from '../assets/img/m.jpeg'
import aImg from '../assets/img/a.jpeg'
import sImg from '../assets/img/s.jpeg'







const modules = [
  {
    image: pImg,
    titre: 'Mes parcelles',
    texte: 'Parce que chaque graine compte, notez ce que vous plantez, suivez sa croissance et sentez la satisfaction de voir arriver la récolte. C\'est votre terrain, vous savez ce qui fonctionne.',
    lien: '/cultures',
    
  },
 {
    image: eImg,
    titre: 'Élevage',
    texte: 'Vos animaux comptent sur vous...',
    lien: '/elevage',
  },
  {
    image: alImg,
    titre: 'Alertes météo',
    texte:
      'La météo ne pardonne pas, mais elle nous prévient. Restez informé des risques à venir pour protéger vos cultures et votre bétail – c\'est ainsi que l\'on travaille main dans la main avec la nature.',
    lien: '/alertes',
    
  },
  {
    image: mImg,
    titre: 'Marché agricole',
    texte:
      'Vos produits méritent d\'être trouvés. Mettez vos annonces en ligne et connectez‑vous directement avec ceux qui cherchent ce que vous produisez. Pas d\'intermédiaire, juste du vrai échange.',
    lien: '/marche',
   
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
    image: aeImg,  // ← Remplacé par ae.jpeg
    titre: 'Agriculteurs & éleveurs',
    texte: 'Vous faites pousser la vie. On vous aide à suivre ce qui pousse, à prendre soin du bétail et à partager vos surplus – avec le respect que votre travail mérite.',
  },
  {
    image: aImg,
    titre: 'Acheteurs',
    texte: 'Trouver des produits locaux qui racontent une histoire, entrer en contact directement avec ceux qui les ont cultivés – c\'est ainsi que le marché devient humain, pas seulement transactionnel.',
    
  },
  {
    image: sImg,
    titre: 'Structures d’appui',
    texte: 'ONG et services techniques : vous n\'êtes pas seul sur le terrain. On est là pour superviser, accompagner et s\'assurer que les outils dont vous avez besoin sont là quand vous en avez besoin.',
    
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
          <p className="accueil-accueillant">
            Pas de formule magique, juste des outils qui évoluent au rythme de votre terrain. On y est
            quand vous décidez de commencer.
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
                {/* L'icône emoji enlevée : l'image réelle du terrain suffit */}
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
                {/* Icône enlevée : l'image parle d'elle-même */}
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
          <h2>Envie d'aller plus loin ?</h2>
          <p>
            Smart AgroTech Sénégal est là quand vous serez prêt – pas de pression, des outils
            qui grandissent avec votre exploitation, à votre rythme.
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

