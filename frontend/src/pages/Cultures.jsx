import PageEnConstruction from '../components/common/PageEnConstruction'

export default function Cultures() {
  return (
    <PageEnConstruction
      icone="🌾"
      titre="Suivi des cultures"
      description="Gérez vos parcelles, suivez l'évolution de vos cultures et anticipez vos récoltes."
      fonctionnalites={[
        'Enregistrer une parcelle (culture, superficie, date de semis) — RF-06',
        'Mettre à jour le statut d’une culture (semis, croissance, récolte) — RF-07',
        'Calendrier prévisionnel des récoltes — RF-08',
        'Rappels d’irrigation, traitement et récolte — RF-09',
      ]}
    />
  )
}
