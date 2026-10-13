import PageEnConstruction from '../components/common/PageEnConstruction'

export default function Elevage() {
  return (
    <PageEnConstruction
      icone="🐄"
      titre="Gestion de l’élevage"
      accroche="Un troupeau en bonne santé, suivi au plus près."
      description="Gérez chaque animal ou lot de votre élevage, consignez les soins vétérinaires et ne manquez plus aucune vaccination ou échéance sanitaire."
      fonctionnalites={[
        'Enregistrer un animal ou un lot (espèce, identifiant, âge)',
        'Consigner les interventions : vaccins, traitements, visites',
        'Suivre la reproduction et la croissance du troupeau',
        'Être alerté avant l’échéance d’une vaccination',
      ]}
    />
  )
}
