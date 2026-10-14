/**
 * Bandeau d'en-tête commun aux modules (Cultures, Élevage, Alertes, Marché).
 * Le badge « Aperçu démo » n'apparaît que si la page est encore une maquette.
 */
export default function BandeauApercu({ icone, titre, texte, apercu = false }) {
  return (
    <div className="bandeau-apercu">
      <span className="bandeau-apercu-icone" aria-hidden="true">{icone}</span>
      <div className="bandeau-apercu-texte">
        <h1>{titre}</h1>
        <p>{texte}</p>
      </div>
      {apercu && <span className="bandeau-apercu-badge">Aperçu démo</span>}
    </div>
  )
}
