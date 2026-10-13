import PageEnConstruction from '../components/common/PageEnConstruction'

export default function Cultures() {
  return (
    <PageEnConstruction
      icone="🌾"
      titre="Suivi des cultures"
      accroche="De la parcelle à la récolte, gardez le contrôle sur vos cultures."
      description="Enregistrez vos parcelles, suivez leur évolution étape par étape et anticipez vos périodes de récolte grâce à un calendrier intelligent."
      fonctionnalites={[
        'Enregistrer une parcelle (culture, superficie, date de semis)',
        'Suivre l’évolution : semis, croissance, floraison, récolte',
        'Consulter un calendrier prévisionnel des récoltes',
        'Recevoir des rappels d’irrigation, de traitement et de récolte',
      ]}
    />
  )
}
