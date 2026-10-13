export default function Message({ type = 'info', children, className = '' }) {
  if (!children) return null
  return (
    <div className={`message message-${type} ${className}`.trim()} role="status">
      {children}
    </div>
  )
}
