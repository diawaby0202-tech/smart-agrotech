export default function Spinner({ taille = 20 }) {
  return (
    <span
      className="spinner"
      style={{ width: taille, height: taille }}
      role="status"
      aria-label="Chargement"
    />
  )
}
