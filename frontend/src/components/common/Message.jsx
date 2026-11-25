export default function Message({ type = 'info', children, className = '' }) {
  if (!children) return null
  return (
    <div className={`message message-${type} ${className}`.trim()} role="status">
      {children}
    </div>
  )
}

/** Messages par défaut selon le type – version humaine */
const MESSAGES_PAR_DEFAUT = {
  info: 'Information',
  succes: 'Bravo !',
  erreur: 'Houps, quelque chose s\'est passé.',
  warning: 'Attention',
}
