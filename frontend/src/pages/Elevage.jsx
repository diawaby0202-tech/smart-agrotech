import PageEnConstruction from '../components/common/PageEnConstruction'

export default function Elevage() {
  return (
    <PageEnConstruction
      icone="🐄"
      titre="Gestion de l'élevage"
      description="Suivez votre bétail, consignez les soins et anticipez les vaccinations."
      fonctionnalites={[
        'Enregistrer un animal ou un lot (espèce, identifiant, âge) — RF-10',
        'Consigner les interventions sanitaires (vaccin, traitement) — RF-11',
        'Suivi de la reproduction et de la croissance — RF-10',
        'Alertes avant échéance de vaccination — RF-12',
      ]}
    />
  )
}
