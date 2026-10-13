import { Link } from 'react-router-dom'
import { useAuth } from '../../context/AuthContext'

/**
 * Tableau de bord administrateur : porte d'entrée vers les outils de
 * supervision (RF-20 à RF-23).
 */
export default function Administration() {
  const { utilisateur } = useAuth()

  const outils = [
    {
      icone: '👥',
      titre: 'Gestion des utilisateurs',
      texte: 'Liste des comptes, validation, suspension et suppression (RF-20, RF-21).',
      lien: '/administration/utilisateurs',
    },
    {
      icone: '📊',
      titre: 'Statistiques globales',
      texte: 'Indicateurs d’utilisation : inscrits, rôles, statuts (RF-23).',
      lien: '/administration/statistiques',
    },
  ]

  return (
    <div className="page-admin">
      <div className="entete-page">
        <h1>Administration</h1>
        <p>
          Bienvenue{utilisateur?.prenom ? `, ${utilisateur.prenom}` : ''} — supervision de la
          plateforme.
        </p>
      </div>

      <div className="grille-modules">
        {outils.map((outil) => (
          <Link to={outil.lien} key={outil.titre} className="carte-module">
            <span className="carte-module-icone" aria-hidden="true">{outil.icone}</span>
            <h3>{outil.titre}</h3>
            <p>{outil.texte}</p>
          </Link>
        ))}
      </div>
    </div>
  )
}
