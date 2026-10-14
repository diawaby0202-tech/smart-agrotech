/**
 * Bandeau d'en-tête commun aux modules en maquette (Cultures, Élevage, ...).
 * Mentionne honnêtement qu'il s'agit d'un aperçu de démonstration.
 */
export default function BandeauApercu({ icone, titre, texte }) {
  return (
    <div className="bandeau-apercu">
      <span className="bandeau-apercu-icone" aria-hidden="true">{icone}</span>
      <div className="bandeau-apercu-texte">
        <h1>{titre}</h1>
        <p>{texte}</p>
      </div>
      <span className="bandeau-apercu-badge">Aperçu démo</span>
    </div>
  )
}
