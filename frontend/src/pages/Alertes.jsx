import PageEnConstruction from '../components/common/PageEnConstruction'

export default function Alertes() {
  return (
    <PageEnConstruction
      icone="⛅"
      titre="Alertes météo & environnementales"
      accroche="Anticipez la météo, protégez vos récoltes et votre bétail."
      description="Consultez les prévisions de votre zone et recevez des alertes précoces en cas de risque climatique, accompagnées de conseils adaptés à votre activité."
      fonctionnalites={[
        'Prévisions météo locales par région et par zone',
        'Alertes en cas de sécheresse, fortes pluies ou canicule',
        'Conseils pratiques adaptés à chaque alerte',
        'Historique de toutes les alertes reçues',
      ]}
    />
  )
}
