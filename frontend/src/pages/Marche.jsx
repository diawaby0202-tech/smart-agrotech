import PageEnConstruction from '../components/common/PageEnConstruction'

export default function Marche() {
  return (
    <PageEnConstruction
      icone="🛒"
      titre="Marché agricole"
      description="Publiez vos annonces de vente et trouvez des produits locaux près de vous."
      fonctionnalites={[
        'Publier une annonce (titre, description, prix, photo) — RF-16',
        'Rechercher par catégorie, zone ou prix — RF-17',
        'Contacter un vendeur — RF-18',
        'Modifier ou supprimer ses propres annonces — RF-19',
      ]}
    />
  )
}
