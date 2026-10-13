import PageEnConstruction from '../components/common/PageEnConstruction'

export default function Alertes() {
  return (
    <PageEnConstruction
      icone="⛅"
      titre="Alertes météo & environnementales"
      description="Consultez la météo de votre zone et soyez alerté des risques climatiques."
      fonctionnalites={[
        'Prévisions météo locales par région — RF-13',
        'Alertes en cas de risque (sécheresse, fortes pluies, chaleur) — RF-14',
        'Conseils contextuels associés aux alertes',
        'Historique des alertes reçues — RF-15',
      ]}
    />
  )
}
