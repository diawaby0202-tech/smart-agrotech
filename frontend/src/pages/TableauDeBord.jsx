import { Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

function salutation() {
  const heure = new Date().getHours()
  if (heure < 12) return 'Bonjour'
  if (heure < 18) return 'Bon après-midi'
  return 'Bonsoir'
}

function texteBienvenue() {
  const heure = new Date().getHours()
  if (heure < 12) return 'Le soleil se lève, c\'est l\'heure de travailler !'
  if (heure < 18) return 'L\'après-midi, parfait pour vérifier vos cultures !'
  return 'Bonsoir, temps de faire le point sur la journée !'
}

// Liste de messages d'encouragement pour rendre l'application plus humaine
const MESSAGES_ENCOURAGEMENT = [
  'Chaque petit pas compte : vous êtes sur la bonne voie ! 🌱',
  'Noubliez pas : la météo peut changer, restez vigilant ! ⛅',
  'Vos cultures vous remercient pour votre attention quotidienne 🌾',
  'Prenez soin de vos animaux, ils comptent sur vous 🐄',
  'Le marché est plein d\'opportunités, allez-y ! 🛒',
  'Chaque jour est une nouvelle chance de réussir vos récoltes.',
  'Votre engagement fait la différence : continuez ainsi !',
  'Petit à petit, l\'oiseau fait son nid : restez patient et persévérant.',
]
function messageEncouragement() {
  // Message aléatoire pour varier l'expérience utilisateur
  const indice = Math.floor(Math.random() * MESSAGES_ENCOURAGEMENT.length)
  return MESSAGES_ENCOURAGEMENT[indice]
}

export default function TableauDeBord() {
  const { utilisateur, estAdmin } = useAuth()

  const prenom = utilisateur?.prenom || ''
  const libelleRole =
    utilisateur?.role === 'admin'
      ? 'Administrateur'
      : utilisateur?.role === 'acheteur'
        ? 'Acheteur'
        : 'Agriculteur / Éleveur'
  const modulesProducteur = [
    { icone: '🌾', titre: 'Mes parcelles', texte: 'Suivre mes cultures et mes récoltes', lien: '/cultures' },
    { icone: '🐄', titre: 'Mon élevage', texte: 'Gérer mes animaux et leur santé', lien: '/elevage' },
    { icone: '⛅', titre: 'Alertes météo', texte: 'Prévisions et risques de ma zone', lien: '/alertes' },
    { icone: '🛒', titre: 'Marché', texte: 'Publier et consulter des annonces', lien: '/marche' },
  ]

  const modulesAcheteur = [
    { icone: '🛒', titre: 'Marché', texte: 'Rechercher des produits locaux', lien: '/marche' },
    { icone: '⛅', titre: 'Alertes météo', texte: 'Suivre la météo de ma région', lien: '/alertes' },
  ]

  const modules = utilisateur?.role === 'acheteur' ? modulesAcheteur : modulesProducteur

  return (
    <div className="page-tableau-de-bord">
      <div className="entete-page apparait">
        <span className="badge badge-vert" style={{ marginBottom: 12 }}>
          {libelleRole}
        </span>
        <h1>{salutation()}{prenom ? `, ${prenom}` : ''} 👋</h1>
<p className="encouragement">{messageEncouragement()}</p>
        <p>Chaque jour est une nouvelle chance de prendre soin de ce qui compte. Voici un aperçu de votre espace Smart AgroTech.</p>
      </div>

      {estAdmin && (
        <div className="bandeau-admin">
          <div>
            <strong>Espace administrateur</strong>
            <p>Vous disposez des droits de supervision de la plateforme.</p>
          </div>
          <Link to="/administration" className="btn btn-primaire">
            Ouvrir l’administration
          </Link>
        </div>
      )}

      <div className="grille-modules">
        {modules.map((module) => (
          <Link to={module.lien} key={module.titre} className="carte-module">
            <span className="carte-module-icone" aria-hidden="true">{module.icone}</span>
            <h3>{module.titre}</h3>
            <p>{module.texte}</p>
            <span className="carte-module-lien">Accéder →</span>
          </Link>
        ))}
      </div>

      <section className="carte carte-info">
        <h2>Mon profil</h2>
        <p>
          Retrouvez vos informations personnelles et mettez-les à jour à tout moment.
        </p>
        <Link to="/profil" className="btn btn-secondaire">
          Voir mon profil
        </Link>
      </section>
    </div>
  )
}
